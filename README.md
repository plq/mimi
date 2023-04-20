Proof of concept repository for the MIMI outer layer proposal.

https://datatracker.ietf.org/doc/draft-arslan-mimi-outer/

```sh
git clone https://github.com/plq/mimi --recursive
make # converts the draft-mimi.md to various formats
make jmap  # re-runs mime => jmap conversion
```

To see the contents of the msgpack files, call this instead:

```sh
make jmap V=1
```

JMAP conversion omits critical stuff like EmailAddress objects in designated
headers. This is just a proof of concept and the converters need more work.
