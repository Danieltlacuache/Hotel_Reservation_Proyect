# Project Structure

This project is in early stages — no source code exists yet. The current repo contains only a README with requirements and system design.

## Current Layout
```
.
├── .kiro/
│   └── steering/       # AI steering rules (this directory)
├── README.md           # Requirements and system design documentation
```

## Expected Structure (based on design)
When implementation begins, expect a microservices layout with separate Lambda handlers per service:

```
.
├── .kiro/
│   ├── specs/          # Feature specs
│   └── steering/       # Steering rules
├── infra/              # AWS CDK infrastructure code
├── services/
│   ├── hotel/          # Hotel management service (Lambda)
│   ├── rate/           # Dynamic pricing service (Lambda)
│   └── reservation/    # Reservation service (Lambda)
├── shared/             # Shared utilities, types, DB models
└── README.md
```

## Conventions
- Each microservice should be independently deployable as a Lambda function
- Shared code (types, DB models, utilities) belongs in a common module
- Infrastructure code (CDK stacks/constructs) is separate from application code
- Update this file as the project structure materializes
