# Troubleshooting Guide

## WSL2 Network Access from LAN

### Problem: Cannot access services from other machines on your network

**Goal:** Access services from devices on your LAN.

**Issue:** WSL2 only exposes ports to the Windows host automatically. Other machines on your LAN cannot reach WSL2 directly.

**Solution (run in PowerShell as Administrator):**

1. **Find your Windows host IP:**
   ```powershell
   ipconfig
   ```
   Note your network IP (e.g., `192.168.0.17`).

2. **Find your WSL IP:**
   ```bash
   ip addr show eth0
   ```
   Note the IPv4 address (e.g., `172.30.15.215`).

3. **Configure port forwarding:**
   ```powershell
   # Forward LiteLLM proxy (Port 4000)
   netsh interface portproxy add v4tov4 listenport=4000 listenaddress=192.168.0.17 connectport=4000 connectaddress=172.30.15.215

   # Forward chat service (Port 8001)
   netsh interface portproxy add v4tov4 listenport=8001 listenaddress=192.168.0.17 connectport=8001 connectaddress=172.30.15.215

   # Allow firewall traffic
   netsh advfirewall firewall add rule name="WSL LiteLLM Port 4000" dir=in action=allow protocol=TCP localport=4000
   netsh advfirewall firewall add rule name="WSL Chat Port 8001" dir=in action=allow protocol=TCP localport=8001

   ```

4. **Restart services:**
   ```bash
   ./run/stop.sh && wsl --shutdown
   ```
   Then from Windows: `wsl --exec ./run/launch.sh`

**Verification:**
```bash
curl http://<windows-ip>:4000/v1/models
```

> **Note:** WSL2 IP addresses can change after restarts, but this is rare. If access stops working after a WSL restart, find the new WSL IP and re-run the port forwarding commands.
