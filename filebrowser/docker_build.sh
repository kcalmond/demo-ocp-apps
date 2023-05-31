git clone https://github.com/jeanchlopez/demo-ocp-apps.git
cd filebrowser
docker build --format docker --build-arg VERSION=v2.23.0 --tag filebrowser:latest .
