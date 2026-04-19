from flask import Flask, render_template, request, redirect, url_for
from db import get_connection

app = Flask(__name__)

@app.route('/')
def dashboard():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Stats for dashboard cards
    cursor.execute("SELECT severity, COUNT(*) as cnt FROM incidents GROUP BY severity")
    severity_counts = {row['severity']: row['cnt'] for row in cursor.fetchall()}
    
    cursor.execute("SELECT COUNT(*) as cnt FROM incidents WHERE status='OPEN'") 
    open_count = cursor.fetchone()['cnt']
    
    # Attack patterns query
    cursor.execute("""
        SELECT attack_type, COUNT(*) AS occurrences, AVG(risk_score) AS avg_risk
        FROM threats GROUP BY attack_type ORDER BY occurrences DESC LIMIT 5
    """)
    attack_patterns = cursor.fetchall()
    
    conn.close()
    return render_template('dashboard.html', 
                           severity_counts=severity_counts,
                           open_count=open_count,
                           attack_patterns=attack_patterns)

@app.route('/incidents')
def incidents():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT i.*, COUNT(e.event_id) as event_count 
        FROM incidents i LEFT JOIN events e ON i.incident_id = e.incident_id
        GROUP BY i.incident_id ORDER BY i.detected_at DESC
    """)
    incidents = cursor.fetchall()
    conn.close()
    return render_template('incidents.html', incidents=incidents)

@app.route('/incidents/<int:id>')
def incident_detail(id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM incidents WHERE incident_id = %s", (id,))
    incident = cursor.fetchone()

    cursor.execute("SELECT * FROM events WHERE incident_id = %s ORDER BY timestamp", (id,))
    events = cursor.fetchall()

    cursor.execute("SELECT * FROM alerts WHERE incident_id = %s ORDER BY triggered_at", (id,))
    alerts = cursor.fetchall()

    cursor.execute("""
        SELECT t.*, v.cve_id, v.cvss_score, v.affected_system
        FROM threats t
        LEFT JOIN vulnerabilities v ON t.vuln_id = v.vuln_id
        WHERE t.incident_id = %s
    """, (id,))
    threats = cursor.fetchall()

    cursor.execute("""
        SELECT * FROM mitigation_actions 
        WHERE incident_id = %s ORDER BY priority DESC
    """, (id,))
    actions = cursor.fetchall()

    conn.close()
    return render_template('incident_detail.html',
                           incident=incident, events=events,
                           alerts=alerts, threats=threats, actions=actions)

@app.route('/incidents/new', methods=['GET', 'POST'])
def new_incident():
    if request.method == 'POST':
        conn = get_connection()
        cursor = conn.cursor()

        # Insert the incident
        cursor.execute("""
            INSERT INTO incidents (title, description, severity, status)
            VALUES (%s, %s, %s, %s)
        """, (
            request.form['title'],
            request.form['description'],
            request.form['severity'],
            request.form['status']
        ))

        # Get the auto-generated incident_id
        new_id = cursor.lastrowid      # ← this is what AUTO_INCREMENT gave us

        # If they filled in an initial event, insert that too
        if request.form.get('event_type'):
            cursor.execute("""
                INSERT INTO events (incident_id, event_type, source_ip, destination_ip, payload)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                new_id,
                request.form['event_type'],
                request.form.get('source_ip'),
                request.form.get('destination_ip'),
                request.form.get('payload')
            ))

        # Auto-generate an alert for HIGH and CRITICAL incidents
        severity = request.form['severity']
        if severity in ('HIGH', 'CRITICAL'):
            cursor.execute("""
                INSERT INTO alerts (incident_id, alert_type, priority, message)
                VALUES (%s, %s, %s, %s)
            """, (
                new_id,
                'AUTO_GENERATED',
                severity,
                f"New {severity} incident logged: {request.form['title']}"
            ))

        conn.commit()
        conn.close()

        # Redirect to the new incident's detail page
        return redirect(url_for('incident_detail', id=new_id))

    return render_template('new_incident.html')

@app.route('/alerts')
def alerts():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM alerts ORDER BY triggered_at DESC")
    alerts = cursor.fetchall()
    conn.close()
    return render_template('alerts.html', alerts=alerts)

@app.route('/risk-report')
def risk_report():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    # Objective 1: Correlate security events with incidents
    cursor.execute("""
        SELECT i.incident_id, i.title, i.severity, i.status,
               COUNT(DISTINCT e.event_id) AS event_count,
               COUNT(DISTINCT a.alert_id) AS alert_count
        FROM incidents i
        LEFT JOIN events e ON i.incident_id = e.incident_id
        LEFT JOIN alerts a ON i.incident_id = a.incident_id
        GROUP BY i.incident_id
        ORDER BY event_count DESC
    """)
    correlated = cursor.fetchall()

    # Objective 2: Identify attack patterns
    cursor.execute("""
        SELECT t.attack_type, t.attack_vector,
               COUNT(*) AS occurrences,
               ROUND(AVG(t.risk_score), 1) AS avg_risk,
               COUNT(DISTINCT t.incident_id) AS incidents_affected
        FROM threats t
        GROUP BY t.attack_type, t.attack_vector
        ORDER BY occurrences DESC
    """)
    patterns = cursor.fetchall()

    # Objective 3: Assess risk — incidents with unpatched critical vulnerabilities
    cursor.execute("""
        SELECT i.title, i.severity, v.cve_id,
               v.cvss_score, v.affected_system, v.patch_status,
               t.attack_type, t.risk_score
        FROM incidents i
        JOIN threats t ON i.incident_id = t.incident_id
        JOIN vulnerabilities v ON t.vuln_id = v.vuln_id
        WHERE v.patch_status = 'UNPATCHED'
        ORDER BY v.cvss_score DESC
    """)
    risk_assessment = cursor.fetchall()

    # Objective 4: Prioritize response — open incidents with pending actions
    cursor.execute("""
        SELECT i.title, i.severity,
               ma.action_type, ma.assigned_to,
               ma.priority AS action_priority, ma.status AS action_status,
               COUNT(e.event_id) AS event_count
        FROM incidents i
        JOIN mitigation_actions ma ON i.incident_id = ma.incident_id
        LEFT JOIN events e ON i.incident_id = e.incident_id
        WHERE i.status IN ('OPEN', 'IN_PROGRESS')
          AND ma.status != 'DONE'
        GROUP BY i.incident_id, ma.action_id, ma.incident_id
        ORDER BY FIELD(i.severity, 'CRITICAL','HIGH','MEDIUM','LOW'),
                 FIELD(ma.priority, 'CRITICAL','HIGH','MEDIUM','LOW')
    """)
    priorities = cursor.fetchall()

    conn.close()
    return render_template('risk_report.html',
                           correlated=correlated,
                           patterns=patterns,
                           risk_assessment=risk_assessment,
                           priorities=priorities)

@app.route('/vulnerabilities')
def vulnerabilities():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    # Read filter from URL — e.g. /vulnerabilities?status=UNPATCHED
    status_filter = request.args.get('status', 'ALL')   # request.args reads GET params

    if status_filter == 'ALL':
        cursor.execute("""
            SELECT v.*,
                   COUNT(DISTINCT t.threat_id) AS threat_count,
                   COUNT(DISTINCT t.incident_id) AS incidents_affected
            FROM vulnerabilities v
            LEFT JOIN threats t ON v.vuln_id = t.vuln_id
            GROUP BY v.vuln_id
            ORDER BY v.cvss_score DESC
        """)
    else:
        cursor.execute("""
            SELECT v.*,
                   COUNT(DISTINCT t.threat_id) AS threat_count,
                   COUNT(DISTINCT t.incident_id) AS incidents_affected
            FROM vulnerabilities v
            LEFT JOIN threats t ON v.vuln_id = t.vuln_id
            WHERE v.patch_status = %s
            GROUP BY v.vuln_id
            ORDER BY v.cvss_score DESC
        """, (status_filter,))

    vulns = cursor.fetchall()

    # Summary counts for the filter buttons
    cursor.execute("""
        SELECT patch_status, COUNT(*) as cnt
        FROM vulnerabilities
        GROUP BY patch_status
    """)
    counts = {row['patch_status']: row['cnt'] for row in cursor.fetchall()}

    conn.close()
    return render_template('vulnerabilities.html',
                           vulns=vulns,
                           counts=counts,
                           status_filter=status_filter)

@app.route('/vulnerabilities/new', methods=['GET', 'POST'])
def new_vulnerability():
    if request.method == 'POST':
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO vulnerabilities
                (cve_id, cvss_score, affected_system, description, patch_status)
            VALUES (%s, %s, %s, %s, %s)
        """, (
            request.form['cve_id'],
            request.form['cvss_score'],
            request.form['affected_system'],
            request.form['description'],
            request.form['patch_status']
        ))
        conn.commit()
        conn.close()
        return redirect(url_for('vulnerabilities'))

    return render_template('new_vulnerability.html')

@app.route('/incidents/<int:id>/delete', methods=['POST'])
def delete_incident(id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM incidents WHERE incident_id = %s", (id,))
    conn.commit()
    conn.close()
    return redirect(url_for('incidents'))

if __name__ == '__main__':
    app.run(debug=True)