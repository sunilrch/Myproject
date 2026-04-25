resource "aws_db_instance" "postgres" {
  engine         = "postgres"
  instance_class = "db.t3.micro"
  allocated_storage = 20

  db_name  = "appdb"
  username = "dbadmin"
  password = "changeme"

  publicly_accessible = false
}