%%%
title = "More Instant Messaging Interoperability (MIMI) Outer Layer"
abbrev = "MIMI Outer"
ipr = "trust200902"
submissiontype = "IETF"
keyword = ["Internet-Draft", "mimi", "json", "xml", "mime", "msgpack", "jmap"]
workgroup = "MIMI"
category = "info"

[seriesInfo]
name = "Internet-Draft"
value = "draft-arslan-mimi-outer-02"
stream = "IETF"
status = "informational"

[[author]]
initials = "B."
surname = "Arslan"
fullname = "Burak Arslan"
organization = "Soba Yazılım A.Ş."

  [author.address]
  email = "burak@soba.email"
      [author.address.postal]
      country = "Turkey"

%%%


.# Abstract

This document describes a general purpose messaging format that is flexible
enough to capture the semantics of incumbent messaging formats like MIME or XMPP
or non-standard protocols like those of apps like WhatsApp, Signal, etc.
It can be used as the payload format inside an MLS session.

{mainmatter}

# Conventions and Definitions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 [@!RFC2119] [@RFC8174]
when, and only when, they appear in all capitals, as shown here.

The reader may wish to note that one of the two RFC references in the
preceding paragraph was normative; the other was informative. These will
be correctly identified as such in the References section below.

# Introduction

Compatibility with existing email systems is a nice property to have. The email
infrastructure is distributed, tries to deal with the spam problem using its own
means and most email clients are robust and feature-rich, built with long-term
archival in mind.

MIME is still the standard format in email exchange. It definitely shows its
age (it's rather complex to implement, text-only, self-contained, etc)
but otherwise stood the test of time so could very well form the basis of a next
generation messaging format.

The JMAP[@!RFC8621] Email object \(§.4\) is one such attempt -- it simplifies
MIME processing by shedding obsolete features like support for non-unicode
character encodings but keeps defining features like being text-only and
recursive structure. The JMAP protocol also adds blob support which adds an
alternate transport for binary data, which not only dramatically lowers the
impact of using a text-only format, but also makes it possible to bundle
arbitrary size or amount of attachments together.

However, email lacks structure, except in very niche applications like meeting
requests, which renders it non-suitable for most of instant messaging
applications.

The history of instant messaging so far makes it obvious that it's not possible
to foresee all actions a client may implement. For example, at the height of its
popularity, the MSN client famously let its users shake the windows of their
peers. WhatsApp is very good at sending plain-text messages, but Snapchat came
up with stickers and expiring messages, which other clients eventually had to
implement.

Any system that seeks to unify message exchange must be flexible enough to
capture and encode any current and future needs of messaging applications.

# MIMI-INK format

We propose the MIMI-INK format, message/mimi-ink, to be renamed to message/mimi
if it gets standardized, which is made of the following elements:

1. A dict of headers. It "MUST" contain the defining entry named
   "Root-Content-Id", among other ones.
2. An optional message body in any number of formats. It's supposed to describe
   the purpose of the message for clients that don't support the attached
   structure, though of course it can be anything.
3. At least one blob that contains the main data structure with
   ``Content-Id: [Root-Content-Id-Value]`` defined in the message headers.
   This is called the "root content".
4. Zero or more additional blobs that may be referenced from inside the main
   structure for any reason.

In MIME terms;

- headers with at least ``Root-Content-Id: XYZ`` and
  ``Content-Type: message/mimi-ink``
- multipart/mixed
    - multipart/alternative
        - text/html
        - text/plain
        - etc.
    - multipart/mixed
        - one of application/{xml,json,msgpack,etc} with ``Content-Id="XYZ"``
        - zero or more binary objects

The root content must at least denote a namespace, name and actual content.
An optional errorcode could also be included, if the content designates an
error message. The client "MUST" validate the content according to the
information given in namespace/name values and refuse to process the message by
resorting to interpret it a regular email message with attachments.

Some examples of this structure serialized as JMAP are as follows:

- https://github.com/plq/mimi/blob/main/reaction.jmap
- https://github.com/plq/mimi/blob/main/vibrate.jmap

We omitted non-essential JMAP properties for sake of simplicity.

Corresponding objects serialized as MIME:

- https://github.com/plq/mimi/blob/main/reaction.eml
- https://github.com/plq/mimi/blob/main/vibrate.eml

The mimi repository above contains software that converts the MIME structure
to the proposed JMAP structure. It is assumed that there is a 1-to-1 releation
between the MIME representation and the JMAP representation of a message, even
though that's not correct -- whatever gets lost in translation is not of
interest.

JMAP standard specifies JSON as serialization format. We think JSON has some
fundamental shortcomings like missing an integer type or being text-only.
So we propose the msgpack format as serialization format for MIME-INK.

Some other key differences with the JMAP Email object are as follows:

1. The "content" property was added to represent inline data where appropriate.
2. The root content needs to represent an abstract structure, serialized as
   any popular format (json, xml, msgpack, etc.).
3. An XML-like namespacing structure needs to be specified so that both
   standards-compliant and proprietary objects can coexist. (Forcing the inner
   layer format to be XML is a good first step.)
4. Using a message body with a well-defined structure makes the recursivity of
   the outer layer (JMAP/MIME) redundant. This kind of structure can be realized
   inside the payload.

# Rationale

## Msgpack

msgpack is;

1. Binary
2. Simple to implement: Here's an implementation in ~400 lines of python:
   https://github.com/plq/msgpack-python-pure/blob/master/msgpack_pure/_core.py
3. Supports enough primitives to be useful: null, true, false, int64, uint64,
   float32, float64, string, bytearray, list, map
4. Doesn't overstep its boundaries by defining complex types like Date

However, there is stuff that needs to be further/better specified:

1. msgpack doesn't have a standard way of defining a schema. We could just
   imitate the relevant bits of XSD.
2. As said above, there is no standard way of serializing complex objects like
   dates.
3. It's very easy to prepend additional headers to MIME, which eg. makes it
   very easy to trace its origins via ``Received`` headers. "Patching" msgpack
   like this doesn't seem practical. However, it's quite easy to tell
   concatenated msgpack objects apart. So it may be desirable to specify MIMI as
   a bunch of concatenated msgpack objects instead of just one object containing
   everything.

If there is a simpler binary format that provides equivalent functionality,
it could be adopted instead. msgpack is not a hard requirement here but does
have interesting properties that make it a strong contender.

## Doing away with recursivity

A MIME/JMAP object can contain an infinite amount of message parts, which can
also contain child message parts. We think:

- Recursive formats like MIME/JMAP add a great deal of flexibility to the wrong
  layer.
- MIMI outer shell needs to be as simple as possible. If a complex message
  bundle is needed, it can be easily expressed by the inner structure(s).
- MIMI objects can be nested as attachments and the clients could choose to
  interpret it further down anyway.

That's why preventing the sub parts from containing further elements could make
sense in order to keep the implementations as simple as possible.

# Content

## Object definitions

When specified in onion-like layers like this, the object definitions become the
subject of another standard. It's off-topic here.

## Validation

To standardize how clients could validate incoming content, we need to specify
or choose a schema language first. XML is the clear winner as the inner format
here as it already has everything, including widespread software support.

# IANA Considerations

The inner format may require IANA to maintain a supported MIMI object types
registry.

{backmatter}
