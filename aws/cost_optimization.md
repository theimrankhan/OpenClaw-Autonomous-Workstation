# AWS Cost Optimization

- Use `m7i-flex.large` Spot with persistent request and `stop` interruption behavior.
- Keep root storage at 50GB gp3, encrypted, delete-on-termination enabled.
- Avoid public ingress and use Tailscale, reducing load balancer and elastic IP cost.
- Stop the instance when idle; persistent service state lives on the root EBS volume while stopped.
- Watch CloudWatch billing alarms separately from this repo if the AWS account has broader usage.
- For longer production use, compare Spot interruption history by Availability Zone and switch region/AZ if interruptions are frequent.
