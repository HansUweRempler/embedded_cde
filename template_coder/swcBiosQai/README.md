# SW Campus BiOS project: QAI


Coder (Terraform) template to automatically setup a QAI development environment.

Optionally deploy a demo QAI service in this development environment.
* modify Python env templates
* inject proxy environment variables
* start docker-compose 
User can then access QAI service via ssh tunnel

```
ssh -L 8080:localhost:8000 user@remote-server
ssh -R 8080:localhost:8000 user@remote-server
```