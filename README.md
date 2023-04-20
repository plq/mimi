Proof of concept repository for the MIMI proposal.

```sh
git clone https://github.com/plq/mimi --recursive
make # converts the draft-mimi.md to various formats
make jmap  # re-runs mime => jmap conversion
```

JMAP conversion omits critical stuff like EmailAddress objects in designated
headers. This is just a proof of concept and the converters need more work.
