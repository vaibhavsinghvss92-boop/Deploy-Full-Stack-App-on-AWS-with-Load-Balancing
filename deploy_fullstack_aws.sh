# ==============================================
# Full Stack Deployment on AWS with Load Balancer
# ==============================================

# ---------- 1. Backend: Node.js / Express App ----------
# File: server.js
cat > server.js <<'EOF'
const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.get('/', (req, res) => {
  res.send('Hello from Node.js backend - served via AWS Load Balancer!');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));
EOF

# Initialize and install dependencies
npm init -y
npm install express cors

# ---------- 2. Frontend: React App ----------
# Create React app (simplified example)
npx create-react-app frontend
cd frontend
cat > src/App.js <<'EOF'
import React from "react";
function App() {
  return (
    <div style={{ textAlign: "center", marginTop: "100px" }}>
      <h1>React Frontend Hosted on AWS EC2</h1>
      <h3>Backend connected through AWS Load Balancer</h3>
      <p>Accessing backend API: <a href="http://<LOAD_BALANCER_DNS>">Click Here</a></p>
    </div>
  );
}
export default App;
EOF
npm run build
cd ..

# ---------- 3. Dockerize Both Apps ----------
# Backend Dockerfile
cat > Dockerfile.backend <<'EOF'
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5000
CMD ["node", "server.js"]
EOF

# Frontend Dockerfile
cat > Dockerfile.frontend <<'EOF'
FROM node:18 as build
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# ---------- 4. Build and Push Docker Images to ECR ----------
# (Use AWS CLI - replace <AWS_ACCOUNT_ID> and <REGION>)
# aws ecr create-repository --repository-name fullstack-backend
# aws ecr create-repository --repository-name fullstack-frontend
# docker build -t fullstack-backend -f Dockerfile.backend .
# docker tag fullstack-backend:latest <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/fullstack-backend:latest
# docker push <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/fullstack-backend:latest

# docker build -t fullstack-frontend -f Dockerfile.frontend .
# docker tag fullstack-frontend:latest <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/fullstack-frontend:latest
# docker push <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/fullstack-frontend:latest

# ---------- 5. AWS Setup ----------
# In AWS Console:
# 1. Create 2 EC2 Instances (Amazon Linux 2 or Ubuntu)
# 2. SSH into each, install Docker:
#    sudo yum install docker -y && sudo service docker start
# 3. Pull and run your images:
#    docker run -d -p 5000:5000 <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/fullstack-backend:latest
#    docker run -d -p 80:80 <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/fullstack-frontend:latest
# 4. Set up Application Load Balancer (ALB):
#    - Target group: backend instances (port 5000)
#    - Listener: port 80 → forward to target group
# 5. Add inbound rules in Security Groups:
#    - Frontend EC2: allow HTTP (80)
#    - Backend EC2: allow HTTP (5000)
#    - ALB: allow HTTP (80)
# 6. (Optional) Add Route 53 custom domain for ALB DNS.

# ---------- 6. Test ----------
# Visit your frontend EC2 public IP or domain (http://<frontend-ip>)
# Click the link to test backend (through ALB DNS).
# The backend response should show: "Hello from Node.js backend - served via AWS Load Balancer!"
