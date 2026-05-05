from flask import Flask, render_template

app = Flask(__name__)

BIO = {
    "name": "Panayiotis Papallis",
    "location": "Nicosia, Cyprus",
}

CONTACTS = [
    {
        "label": "Email",
        "value": "panayiotis@papallis.com",
        "href": "mailto:panayiotis@papallis.com",
    },
    {
        "label": "LinkedIn",
        "value": "panayiotis-papallis",
        "href": "https://www.linkedin.com/in/panayiotis-papallis-a1737732",
    },
    {
        "label": "Company",
        "value": "immix.com.cy",
        "href": "https://immix.com.cy",
    },
]

SKILL_GROUPS = [
    {
        "title": "Infrastructure & Systems",
        "items": [
            "Linux Server Administration",
            "Windows Server",
            "Virtualization (Proxmox, VMware, Hyper-V)",
            "High-Availability & Failover Design",
            "Backup, Disaster Recovery & Business Continuity",
            "Monitoring & Observability",
        ],
    },
    {
        "title": "Networking",
        "items": [
            "TCP/IP & Routing",
            "Firewalls & VPN (Site-to-Site, Remote Access)",
            "VLANs & Managed Switching",
            "Wi-Fi Design & Deployment",
            "Structured Cabling & Datacenter Wiring",
            "DNS, DHCP & Network Troubleshooting",
        ],
    },
    {
        "title": "Cloud & DevOps",
        "items": [
            "Cloud Computing (AWS, Azure, Hetzner)",
            "Docker & Containerization",
            "Infrastructure as Code",
            "CI/CD Pipelines",
            "Reverse Proxies & TLS (Nginx, Caddy)",
            "Linux Hardening & Security Best Practices",
        ],
    },
    {
        "title": "Databases & Data",
        "items": [
            "PostgreSQL, MySQL & MS SQL Server",
            "Schema Design & Query Optimization",
            "Backup, Replication & Migration",
            "Reporting & Data Integration",
        ],
    },
    {
        "title": "Software & Automation",
        "items": [
            "Python (Automation, Web, Scripting)",
            "C / Low-Level Programming",
            "Bash & Shell Scripting",
            "REST APIs & Web Services",
            "Git & Version Control",
        ],
    },
    {
        "title": "Business & Operations",
        "items": [
            "POS Systems Architecture & Integration",
            "Technical Leadership & Team Management",
            "Vendor & Client Relationship Management",
            "Project Delivery & On-Site Deployment",
            "End-to-End Troubleshooting",
        ],
    },
]

PROJECTS = [
    {
        "name": "Childhood Movies",
        "url": "https://childhoodmovies.bikitsos.com",
        "description": "A nostalgic catalogue of childhood films.",
    },
    {
        "name": "What Is My IP",
        "url": "https://whatismyip.bikitsos.com",
        "description": "Quick lookup tool for your public IP address and details.",
    },
    {
        "name": "SnapTrack",
        "url": "https://snaptrack.bikitsos.com",
        "description": "Convert and download YouTube videos as MP3 audio files.",
    },
    {
        "name": "BG Remover",
        "url": "https://bgremover.bikitsos.com",
        "description": "Remove backgrounds from images right in your browser.",
    },
]


@app.route("/")
def index():
    return render_template(
        "index.html",
        bio=BIO,
        contacts=CONTACTS,
        skill_groups=SKILL_GROUPS,
        projects=PROJECTS,
    )


if __name__ == "__main__":
    app.run(debug=True)
