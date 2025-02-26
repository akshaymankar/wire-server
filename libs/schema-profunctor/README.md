# Schemas for documented bidirectional JSON encoding

## Introduction

A value of type `SchemaP d v w a b`, which we will refer to as a
*schema*, contains both a JSON parser and a JSON serialiser,
together with documentation-like metadata, such as a JSON or
Swagger schema.

The type variables are as follows:

 - `d`: documentation type, usually a `Monoid`.
 - `v`: type of JSON values being parsed (e.g. `Value`).
 - `w`: type of JSON values being serialised (e.g. `Value`).
 - `a`: input type.
 - `b`: output type.

Input and output types deserve some more explanation. We can think
of a value `sch` of type `SchemaP d v w a b` as a kind of special
"function" from `a` to `b`, but where `a` and `b` might potentially
live in different "languages". The parser portion of `sch` takes a
JSON-encoded value of type `a` and produces a value of type `b`,
while the serialiser portion of `sch` takes a haskell value of type
`a` and produces a JSON-encoding of something of type `b`.

In terms of composability, this way of representing schemas (based
on input and output types) is superior to the perhaps more natural
approach of using "bidirectional functions" or isomorphisms (based
on a single type parameter).

Although schemas cannot be composed as functions (i.e. they do not
form a `Category`), they still admit a number of important and
useful instances, such as `Profunctor` (and specifically `Choice`),
which makes it possible to use prisms quite effectively to build
schema values.

Using type variables to represent JSON types might seem like
excessive generality, but it is useful to represent "intermediate"
schemas arising when building complex ones. For example, a schema
which is able to work with fields of a JSON object (see `field`)
should not output full-blown objects, but only lists of pairs, so
that they can be combined correctly via the usual `Monoid`
structure of lists when using the `Applicative` interface of
`SchemaP d v w a b`.

## Tutorial

To learn how to use `SchemaP` in practice, let us walk through some
basic examples, including records and sum types.

### Records

Consider the following record:

```haskell
data Person = Person
  { name :: Text
  , age :: Int }
```

we can produce a schema for `Person` as follows:

```haskell
personSchema :: ValueSchema NamedSwaggerDoc Person
personSchema = object "Person" $ Person
  <$> name .= field "name" schema
  <*> age .= field "age" schema
```

This simply builds up the schema for `Person` in terms of the ones for
`Text` and `Int`, as an object containing the fields `"name"` and
`"age"`.

Let us break down the example to see what the types look like at each
stage of the construction.

If we focus on the second line of the definition (after `<$>`) and
move right to left, we start with a call to `schema`, which is the
only method of the `ToSchema` class. This returns a schema for `Text`,
i.e. a `SchemaP` value `Text ~> Text`, by which we mean that the input
and output types are both `Text`.

After that, we use the `field` combinator to turn it into a
single-field object schema. This does not change the type, but it
changes the behaviour of both the parser and the pretty-printer. Used
by itself, this schema would convert JSON objects of the form `{
"name": "Bob" }` with the haskell value `"Bob" :: Text`, in both
directions.

Now, we use the `(.=)` combinator (which is an infix synonym for the
`lmap` method of `Profunctor`) to turn this into a schema `Person ~>
Text`. We are not changing the runtime behaviour of the schema in any
significant way. We are only modifying the input type. Now a JSON
object containing a whole `Person`, say `{ "name": "Bob", age: 42}`
will be converted to the haskell value `"Bob" :: Text`.

Let us pause here to observe how at this stage we have significantly
departed from the idea that a schema should somehow represent an
isomorphism between JSON and haskell values. The schema we have built
so far cannot possibly be an isomorphism, because it is a mapping
between two different types. This generality is important, since it
makes it possible to construct schemas incrementally, as we are doing
in this example: even though the final schema one is interested in
might well be an isomorphism, it is almost never possible to obtain it
compositionally by only going through isomorphisms.

At this point, we are almost done. The next line of the example
constructs a similar object schema, this time `Person ~> Int`,
corresponding to the "age" field. To put them all together, we simply
use the `Applicative` instance of `SchemaP`:

```haskell
Person <$> nameSchema <*> ageSchema
```

where `nameSchema` and `ageSchema` stand for the two schemas we
described above. The `Applicative` interface of `SchemaP` changes the
output type. At the level of the pretty printer, it simply
"concatenates" the outputs using a `Monoid` instance for the
corresponding JSON values (in this case, list of key-value pairs). At
the level of the parser, it combines them in the usual applicative
sense (i.e. by sequencing).

Finally, we want to turn this special schema, which can only parse
objects and outputs lists of pairs, into a general-purpose "value"
schema, i.e. one that can parse and serialise arbitrary JSON
values. This can be done using the `object` combinator, which
incidentally also takes a name for the schema and uses it for both the
documentation and parsing errors.

### Lists

Consider the following record:

```haskell
data Invite = Invite
  { users :: NonEmpty UserId
  , permissions :: [Permission] }
```

we can produce a schema for `Invite` as follows:

```haskell
inviteSchema :: ValueSchema NamedSwaggerDoc Invite
inviteSchema = object "Invite" $ Invite
  <$> users .= field "users" (nonEmptyrray schema)
  <*> permissions .= field "permissions" (array schema)
```

Here, we cannot use `schema` to deduce the schema for the list or the
NonEmpty list, as there are no instances for `ToSchema [a]` or
`ToSchema (NonEmpty a)`. So, the combinators `array` and
`nonEmptyArray` can be used to derive a schema for these if there are
`ToSchema` instances for `UserId` and `Permission`.

### Sum types

Let us now look at a similar example, but based on sum types.

```haskell
data Detail
  = Name Text
  | Age Int
```

Here is how we can implement a schema for `Detail`:

```haskell
detailSchema :: ValueSchema NamedSwaggerDoc Detail
detailSchema = named "Detail" $
  tag _Name schema <>
  tag _Age schema
```

Again, we can examine this value by moving right to left starting from
the second line of the definition. Once again, the `schema` call
builds a schema for `Text`, using a builtin instance of `ToSchema`.

Next, we use `tag` to turn a schema `Text ~> Text` into a schema
`Detail ~> Detail`. The first argument of `tag` is a *prism* of type
`Prism' Detail Text`, which can be automatically generated using
`makePrisms` from the lens library.

The use of a prism here is necessary, because it gives the pretty
printer a way to examine whether a value of type `Detail` happens to
be "tagged" with `Name`. For those not familiar with optics, it helps
to think of the prism `_Name` as a pair consisting of the constructor
`Name :: Text -> Detail`, and a partial function `Detail -> Maybe
Text`, which checks if a detail is actually a name, and if so returns
the actual name.

After tagging, the resulting schema is able to translate between a JSON
value such as `"Bob"` and the corresponding haskell value `Name
"Bob"`.

To put this schema and the analogous one for `Age` together, we can
now simply use the `Monoid` instance. At the parser level, this works
just like an `Alternative` instance, i.e. it tries parsing the various
cases one by one until it succeeds. Similarly, at the serialiser
level, it tries every case until the underlying lens returns a `Just`.

Finally, we add a name to the schema using the `named`
combinator. This does nothing to the JSON encoding-decoding part of
the schema, and only affects the documentation.

### Enumerations

As a special case of sum types, we have *enumerations*, where every
summand is a unit type (i.e. the corresponding constructor has no
arguments). These require some special support, so there are specific
combinators `element` and `enum`, which can be used to produce schemas
for enumerations.

For example, consider the type:

```haskell
data Access
  = PrivateAccess
  | InviteAccess
  | LinkAccess
  | CodeAccess
```

We can define a schema for `Access` as follows:

```haskell
accessSchema :: ValueSchema NamedSwaggerDoc Access
accessSchema = enum @Text "Access" $
  mconcat
    [ element "private" PrivateAccess,
      element "invite" InviteAccess,
      element "link" LinkAccess,
      element "code" CodeAccess
    ]
```

The `element` combinator takes two arguments: the value corresponding to
a case alternative on the JSON side, and the corresponding value on the
Haskell side. All the intermediate schemas returned by `element` are
joined together using the `Monoid` instance, and finally passed to
`enum`, which takes care of creating the final schema. Note the `@Text`
type annotation for `enum`, which is required when using
`OverloadedStrings`.

Similar schema definitions can be used for enumerations that are
implemented using types other than strings on the JSON side. For
example:

```haskell
data ConvType
  = RegularConv
  | SelfConv
  | One2OneConv
  | ConnectConv

convTypeSchema = enum @Integer "ConvType" $
  mconcat
    [ element 0 RegularConv,
      element 1 SelfConv,
      element 2 One2OneConv,
      element 3 ConnectConv
    ]
```

uses integers instead of strings for the enumeration values on the JSON
side.

### Tagged unions

It is important to note how the sum type example above is realised as a
"tagged" union on the haskell side, but an "untagged" one on the JSON
side. That means that the JSON values that this schema parses and
produces distinguish the two cases simply using the type of the
underlying value. In particular, this approach would not work for sums
that cannot be distinguished in this way, like for example `Either Int
Int`.

In those cases, one can for example make use of the `field` and `object`
combinators to move values inside JSON objects, and use the keys as tags
on the JSON side. Ultimately, since JSON does not directly have a notion
of sum types, how these types are represented is up to the application,
and the `SchemaP` combinators have enough flexibility to accommodate
most choices of encoding.

For example, consider the `Detail` type again:

```haskell
data Detail
  = Name Text
  | Age Int
```

but this time, we want to create a schema where the correct summand is tagged on the JSON side by wrapping the value corresponding to a `Detail` into a JSON object containing a `tag` field, like:

```json
{"tag": "name", "value": "Alice"}
```

This can be achieved by introducing a type for tags, and using the
`bind` and `dispatch` combinators as follows:

```haskell
data DetailTag = NameTag | AgeTag
  deriving (Eq, Enum, Bounded)

tagSchema :: ValueSchema NamedSwaggerDoc DetailTag
tagSchema = enum @Text "Detail Tag" $
  mconcat [ element "name" NameTag, element "age" AgeTag ]

detailSchema :: ValueSchema NamedSwaggerDoc Detail
detailSchema = object "Detail" $
  fromTagged <$> toTagged .= bind
    (fst .= field "tag" tagSchema)
    (snd .= fieldOver _1 "value" untaggedSchema)
  where
    toTagged :: Detail -> (DetailTag, Detail)
    toTagged d@(Name _) = (NameTag, d)
    toTagged d@(Age _) = (AgeTag, d)

    fromTagged :: (DetailTag, Detail) -> Detail
    fromTagged = snd

    untaggedSchema = dispatch $ \case
      NameTag -> tag _Name (unnamed schema)
      AgeTag -> tag _Age (unnamed schema)
```

Here `bind` provides a limited monadic interface for `SchemaP`: its
first argument is a parser for some "tag" value, which in this case is
simply an enumeration schema for `DetailTag`, while the second argument
is a special schema whose parser part takes a tag as an extra argument.

Almost always, one is supposed to create this second argument for `bind`
using the `dispatch` combinator, which takes a function mapping tag
values to their corresponding schemas. Note that the tag type is
required to have instances for `Bounded` and `Enum`, to ensure that we
are able to generate a (finite) documentation for the dispatching
parser.

The schema returned by `bind` is for a pair of a tag and a value, so in
the example we use `toTagged` and `fromTagged` to convert it back and
forth to simply a value of type `Detail`. This part might be different
in other situations, depending on how exactly the tagged union is
represented on the Haskell side.

### Optional fields and default values

To define a schema for a JSON object, there are multiple ways to deal with the
serialisation of optional fields, which we will illustrate here.

The simplest (and most common) scenario is an optional field represented by a
`Maybe` type, that is simply omitted from the generated JSON if it happens to
be `Nothing`.

For example:

```haskell
data User = User
  { userName :: Text,
    userHandle :: Maybe Text,
    userExpire :: Maybe Int
  }

userSchema = object "User" $
  User
    <$> userName .= field "name" schema
    <*> userHandle .= maybe_ (optField "handle" schema)
    <*> userExpire .= maybe_ (optField "expire" schema)
```

Here we use `optField` to define schemas for optional fields, and apply the
`maybe_` combinator to the result, which has the effect of making the
serialiser omit the field when the corresponding value is `Nothing`.

In detail, `optField "handle" schema` returns a schema from `Text` to `Maybe
Text`, i.e. a schema that is able to parse an optional text value, but does not
know how to serialise `Nothing`. Wrapping it in `maybe_` changes the first type
to `Maybe Text`, and gives the serialiser the ability to serialise `Nothing` as
well.

Another possibility is a field that, when missing, is assumed to have a given
default value. Most likely, in this case we do not want the field to be omitted
when serialising. Such a schema can be defined simply by omitting the call to
`maybe_`, and instead converting a `Nothing` value coming from the parser into
the desired default value.

```haskell
userSchemaWithDefaultName :: ValueSchema NamedSwaggerDoc User
userSchemaWithDefaultName =
  object "User" $
    User
      <$> userName .= (fromMaybe "" <$> optField "name" schema)
      <*> userHandle .= maybe_ (optField "handle" schema)
      <*> userExpire .= maybe_ (optField "expire" schema)
```

Now the `name` field is optional, and it is set to the empty string when
missing.  However, the field will still be present in the generated JSON when
its value is the empty string. If we want the field to be omitted in that case,
we can instead use the first approach, and manually convert back and forth from
`Maybe Text`.

```haskell
userSchemaWithDefaultName' :: ValueSchema NamedSwaggerDoc User
userSchemaWithDefaultName' =
  object "User" $
    User
      <$> (getOptText . userName) .= maybe_ (fromMaybe "" <$> field "name" schema)
      <*> userHandle .= opt (field "handle" schema)
      <*> userExpire .= opt (field "expire" schema)
  where
    getOptText :: Text -> Maybe Text
    getOptText "" = Nothing
    getOptText t = Just t
```

In some cases, it might be desirable for the serialiser to output a field even
when its value is `Nothing`. In that case, we can essentially combine the
techniques of the previous two examples:

```haskell
userSchema' :: ValueSchema NamedSwaggerDoc User
userSchema' = object "User" $ User
  <$> userName .= field "name" schema
  <*> userHandle .= optField "handle" (maybeWithDefault Aeson.Null schema)
  <*> userExpire .= opt (field "expire" schema)
```

Two things to note here:

 - we are now using `maybeWithDefault` instead of `maybe_`. This is a more
 general version of `maybe_` that takes as an argument the value to use when
 serialising `Nothing`. Not that `maybe_` is simply `maybeWithDefault mempty`.
 - the `maybeWithDefault` combinator is applied to the schema value *inside*
 `field`, because the value to use when serialising `Nothing` (`Aeson.null` in
 this case) applies to the value of the field, and not the containing
 (one-field) object, as in the previous examples.

One might wonder why we are using the special combinator `optField` here
instead of simply using the `Alternative` instance (via `optional` or
directly), on the schema returned by the `field` combinator. The reason is that
the `Alternative` instance would result in a slightly surprising behaviour in
case of errors in the JSON value contained in a field.

For example, given a field of the form

```haskell
optional (field "name" schema)
```

the corresponding parser will return `Nothing` not only in the case where the
`"name"` field is missing, but also if it is fails to parse correctly (for
example, if it has an unexpected type).  This behaviour is caused by the fact
that `optional` is implemented in terms of the `Alternative` instance for
`Aeson.Parser`, which cannot distinguish between "recoverable" and
"unrecoverable" failures.

In some cases, this behaviour can be acceptable (or even desired), but in most
circumstances, it is better to define the above schema using the dedicated
`optField` combinator, as in:

```haskell
optField "name" schema
```

### Asymmetric types

There might be a case where an asymmetry between the haskell type
and the serialised type exists. In those cases, the following example might
clarify usage.

```haskell
data AssocList
  = AssocList { unList :: [Text] }

instance ToSchema AssocList where
  schema =
    object "AssocList" $
      AssocList
        <$> unList .= field "elements" (array schema)
        <* const (1 :: Int) .= field "version" schema
```

As you can see, we use a different name for our field between the two domains,
but we also have a field that only exists in the serialised structure.

For these cases we can take advantage of Applicative and use the
left-side `<*` or right-side `*>` biased operators, depending in which direction
we want the value to be added.

### Transformations on intermediate values

Sometimes a type on the Haskell side doesn't neatly translate to a type
in the serialised side. For those cases, some transformations need apply.

Transformations can be applied on either or both sides of the Schema.

``` haskell

data RecordField
  = RecordField
      { rfType :: SomeTypeOf Text
      , rfValue :: Text
      }

instance ToSchema RecordField where
  schema =
    object "RecordField" $
      RichField
        <$> rfType .= field "type" (SomeTypeOf.unwrap .= (SomeTypeOf.wrap <$> schema))
        <*> rfValue .= field "value" schema
```

Here a transformation is applied on the left side, `SomeTypeOf.unwrap` and on the
right side as well, `SomeTimeOf.wrap`. If we remember that Schema is a profuctor,
and as such, is contravariant on the first term but covariant on the second, by
using `fmap` on one, and `lmap` (`.=`) on the other, we can compose it.

### Redundant fields

Sometimes, JSON encoding of haskell types is not as straightforward as
in the previous examples. For example, for backward-compatibility
reasons, it might be necessary to serialise an object with some extra
redundant information, which is then ignored when parsing.

The `SchemaP` combinator language is powerful enough to express these
sort of use cases quite concisely.

For example, consider a record type like:

```haskell
data Person = Person
  { firstName :: Text
  , lastName :: Text
  -- ... potentially other fields here
  }
```

If an old version of the application was working with a `fullName ::
Text` field instead of first/last, we can retain some form of
backwards compatibility for consumers of our JSON output if we simply
add a redundant `"full_name"` field in the serialised object.

Here is how to achieve this using `SchemaP`:

```haskell
personSchema = object "Person" $ Person
  <$> firstName .= field "first_name" schema
  <*> lastName .= field "last_name" schema
  <* fullName .= optional (field "full_name" schema)
  where
    fullName p = firstName p <> " " <> lastName p
```

Most of this schema definition should be familiar if you have followed
the record example above, but there are a few new ideas.

First, note that the `where` clause is defining a function `fullName`,
which is a normal haskell function `Person -> Text`.

Next, a `"full_name"` schema is constructed in the usual way, as a
schema of type `Text ~> Text`. However, since we do not want to
require this field when parsing, we wrap it inside `optional`, which
is a standard combinator in `Control.Applicative`. This makes it
indeed optional at the parser level, and changes its type to `Text ~>
Maybe Text`. The schema will convert between JSON values of the form
`{ "full_name": "Bob Ross" }` and `Just "Bob Ross" :: Maybe Text`.

At this point, we lift it to the level of `Person` by using our custom
`fullName` function with the `(.=)` combinator. Now the schema has
type `Person -> Maybe Text`. Given a whole object for a `Person`
value, it will extract its optional `full_name` field. In the other
direction, given a haskell value of type `Person`, it will output a
JSON object with just the `full_name` field.

Now we can assemble this field schema and the simple ones for first
and last name to obtain a schema for the whole `Person` type. This
works just like before, using the `Applicative` interface. The only
caveat is that, since we do not need the full name value of type
`Maybe Text` in order to reconstruct a person, we simply ignore it by
using the `<*` combinator from `Control.Applicative`.
