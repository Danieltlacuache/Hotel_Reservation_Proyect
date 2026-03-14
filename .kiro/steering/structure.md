# Project Structure

This project is in early stages. Infrastructure configuration exists as CloudFormation, but no application source code yet.

## Current Layout
```
.
├── .kiro/
│   └── steering/       # AI steering rules (this directory)
├── infra/
│   └── hotel-reservation-system.yaml  # CloudFormation template (full stack)
├── README.md           # Requirements and system design documentation
```

## Expected Structure (based on design)
When implementation begins, expect a microservices layout with separate Lambda handlers per service:

```
.
├── .kiro/
│   ├── specs/          # Feature specs
│   └── steering/       # Steering rules
├── infra/              # CloudFormation / AWS CDK infrastructure code
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
