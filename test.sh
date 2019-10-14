#!/bin/bash


fails=""

inspect() {
  if [ $1 -ne 0 ]; then
    fails="${fails} $2"
  fi
}

# run unit and integration tests
docker-compose -f testdrivenapp/docker-compose.yml up -d --build
docker-compose -f testdrivenapp/docker-compose.yml exec users python manage.py test
inspect $? users
docker-compose -f testdrivenapp/docker-compose.yml exec users flake8 project
inspect $? users-lint
docker-compose -f testdrivenapp/docker-compose.yml exec client npm test -- --coverage
inspect $? client
docker-compose -f testdrivenapp/docker-compose.yml down

# new
# run e2e tests
docker-compose -f testdrivenapp/docker-compose-prod.yml up -d --build
docker-compose -f testdrivenapp/docker-compose-prod.yml exec users python manage.py recreate_db
./node_modules/.bin/cypress run --config baseUrl=http://localhost
inspect $? e2e
docker-compose -f testdrivenapp/docker-compose-prod.yml down

# return proper code
if [ -n "${fails}" ]; then
  echo "Tests failed: ${fails}"
  exit 1
else
  echo "Tests passed!"
  exit 0
fi