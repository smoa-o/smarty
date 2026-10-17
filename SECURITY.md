# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| build1 (current) | Yes |
| Earlier versions | No |

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public Issues.**

If you discover a security vulnerability in the ST-16 / Smarty project, please report it privately:

- **Email**: sauthm_2015@qq.com
- **QQ Private Message**: Contact the maintainer (admin in QQ Group 183241333)

Please include the following information:

- Vulnerability type and brief description
- Affected components (ISA manual volume / Verilog module name)
- Steps to reproduce or proof-of-concept (PoC)
- Potential exploit scenarios and impact assessment

## Response Process

1. **Acknowledgment**: Maintainer confirms receipt within 7 days
2. **Initial Assessment**: Vulnerability evaluated and severity rated within 30 days
3. **Fix Development**: Remediation plan developed based on severity
4. **Coordinated Disclosure**: Disclosure timing coordinated with reporter after fix is ready

## Severity Levels

| Level | Definition | Example |
|---|---|---|
| Critical | Hardware-level vulnerability enabling arbitrary code execution, privilege escalation, or information disclosure | Side-channel attack, privilege bypass |
| High | Vulnerability causing denial of service or system instability | Malformed instruction causing CPU deadlock |
| Medium | Limited-impact vulnerability requiring specific conditions | Incorrect boundary condition handling |
| Low | Minimal impact or extremely difficult to exploit | Implementation deviation due to documentation ambiguity |

## Disclosure Policy

- We follow **coordinated disclosure**: vulnerability details will not be made public until a fix is ready
- Reporters may remain anonymous
- After fix and disclosure, reporters will be credited (unless anonymity is requested)

## Special Note

This project is a hardware CPU implementation. Since hardware vulnerabilities cannot be patched after fabrication, we place special emphasis on:

- Security review during ISA design phase
- Boundary condition verification at implementation level
- Evaluation of hardware-specific threats such as side-channels and timing attacks

If you identify design flaws that could impact hardware security, please report them privately so we can address them at the design stage.
