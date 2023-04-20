#!/usr/bin/env python3

import sys, json, re

from io import BytesIO

from base64 import b64encode

from email.parser import BytesParser
from email.policy import default

from jmapd.model.mail import *

from spyne.util.web import log_repr
from spyne.util.dictdoc import get_object_as_json
from spyne.util.dictdoc import get_object_as_msgpack


def strip_angle(s):
    if s is None:
        return
    return re.sub("<(.*)>", "\\1", s)


as_msgpack = False

for fn in sys.argv[1:]:
    if fn == "-m" or fn == "--msgpack":
        as_msgpack = True
        continue

    with open(fn, "rb") as fp:
        fdata = fp.read()
        # without this, the python email parser won't parse the message body
        fdata = fdata.replace(b"message/mimi-ink;", b"multipart/mixed;", 1)
        patched = BytesIO(fdata)

    message = BytesParser(policy=default).parse(patched)

    from_ = []
    for addr in message["from"].addresses:
        from_.append(EmailAddress(name=addr.display_name, address=addr.addr_spec))

    to = []
    for addr in message["to"].addresses:
        to.append(EmailAddress(name=addr.display_name, address=addr.addr_spec))

    text_body = EmailBodyPart()
    root_body = EmailBodyPart()

    for c in message.get_payload():
        if c.get_content_type() == "text/plain":
            text_body.type = "text/plain"
            text_body.charset = c.get_content_charset()
            text_body.content = c.get_payload()

        if c["Content-Id"] == message["Root-Content-Id"]:
            root_body.type = c.get_content_type()
            root_body.content = c.get_content()

    email = Email(
        headers=[EmailHeader(name=k, value=v) for k, v in message.items()],
        thread_id=strip_angle(message["Thread-Id"]),
        message_id=[strip_angle(message["Message-Id"])],
        in_reply_to=[strip_angle(message["In-Reply-To"])],
        from_=[addr.address for addr in from_],
        to=[addr.address for addr in to],
        subject=message["subject"],
        received_at=datetime.utcnow().replace(tzinfo=pytz.utc),
        sent_at=message["Date"].datetime,
        text_body=[text_body],
        root_body=root_body,
    )

    if as_msgpack:
        #
        # The following snippet can be used to inspect the generated msgpack file:
        #
        # $ python3 -q
        # >>> import msgpack; msgpack.unpack(open('reaction.jmap.msgpack', 'rb'), raw=False)
        #

        output = get_object_as_msgpack(email, complex_as=dict, ignore_wrappers=True)

    else:
        # this is a hack to force the bytes object to be serialized to json
        # not needed when using msgpack
        if root_body.content is not None:
            try:
                root_body.content = root_body.content.decode("utf8")
            except:
                root_body.content = b64encode(root_body.content).decode("ascii")

        output = get_object_as_json(
            email,
            complex_as=dict,
            indent=2,
            ensure_ascii=False,
        )

    sys.stdout.buffer.write(output)
