+++
title = "Powershell is not my favourite scripting language"

[taxonomies]
tags = ["rant", "powershell"]
+++

I had half my weekend wasted by this inane scripting language, and I need a
self-therapy session masquerading as a blog post.

Before you discount this as the ravings of a UNIX fanboy, please understand that you couldn't
be further from the truth. I sincerely tried to be fair and gave Powershell as much benefit of the
doubt as I could muster.

Disclaimers aside, let's begin the descent into madness.

<!-- more -->

## Why use shell scripts?

Generally, shell scripts are used when a task needs to be automated, but it's not worth pulling out
a "real" (see: time-consuming) programming language. Given this, it stands to reason that shell scripting languages should
be quick and easy to learn. If it's easier to write a program
than it is to write a shell script, it has failed to serve its only purpose.

> Foreshadowing is a narrative device in which suggestions or warnings about events to come are dropped or planted.

## The veritable mess that is POSIX

POSIX shell is, like most things descending from UNIX, poorly designed and
incredibly unpleasant to use. Once you've developed a mental model of how it works via abstract
causality and pain, you can eventually kludge together scripts _relatively_ quickly. It has many warts, though, namely inconsistency, error-prone string handling, and its
compulsion to violate the principle of least surprise.

POSIX shell is a concrete example of ["worse is better"] in action. It's a glue used to create
precarious and unholy obelisks comprised of disjoint software, many of which date back to the 70s.

There's barely _any_ language in there to speak of; most of the "syntax" is just _other_ programs.

Control flow?

```
❯ which [
/bin/[
```

Constants?
```
❯ which true
/usr/bin/true
```

Oh, it's another program.

Furthermore, lacking a standard for structuring data means relying on ad-hoc conventions, such as
`find`'s `-print0` parameter, which separates results by an ASCII `NUL` character. I hope
whatever you're piping `find` into supports this, or you'll have to add _yet more_ slop
to handle it!

I don't like POSIX shell, and I struggle to see how _anyone_ could like POSIX shell.
I have spent an embarrassing amount of my life writing and
debugging POSIX shell scripts, yet it still _regularly_ surprises me, as if it's mocking me for
trying to comprehend it.

> Sometimes, foreshadowing can be relatively obvious.

## Introducing Powershell

This brings us to Powershell. In concept, I quite like Powershell. Equipped with several
decades of hindsight, it seeks to be a shell scripting language that doesn't make you reconsider your
life decisions.

It is with regret, my dear reader, that I inform you Powershell is just as bad in a variety of new and exciting ways.
The rest of the post details my first-time user experience with Powershell.

### Running a command

Do you know what shell scripts frequently do? Run programs. They run other programs.

To run programs in Powershell, you can either:

1) run it [directly](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/running-commands?view=powershell-7.4#running-native-commands)
2) use the [call operator](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.4#call-operator-)
3) or, use [`Start-Process`]

Let's do it the "Powershell way" and use [`Start-Process`]:

```pwsh
Start-Process -Wait -FilePath 'my\amazing\custom\app.exe' -ArgumentList 'hello' 'C:\this has spaces\foo.txt' 'another parameter' 'wow so many parameters!' "-yak-type=$yak_type"
```

### Wait, how do I break lines?

Hmm, this line is getting rather long. Now that I think about it, all the examples I see of Powershell code run off the page... I wonder why?

Anyway, let's make this more legible by splitting the command over multiple lines.

To split lines in Powershell, you can either:

1) use a backtick:
    ```pwsh
    # I'm not making this up—the space before the backtick is required. Why?
    Get-ChildItem -Recurse `
        -Filter *.jpg
    ```
2) use a pipe:
    ```pwsh
    Get-ChildItem |
        Select Name,Length
    ```

Oh, by the way, both methods are [finnicky](https://stackoverflow.com/a/53575932) and prone to [breaking code](https://devblogs.microsoft.com/scripting/powershell-code-breaks-break-line-not-code/).

### Array coercion?

Let's sidestep this nonsense by defining the arguments beforehand.

```pwsh
# You can define arrays like this:
[string[]] $args = 'hello', 'C:\this has spaces\foo.txt', 'another parameter', 'wow so many parameters!', "-yak-type=$yak_type"

# Or, like this:
[string[]] $args = @(
    # Using a trailing comma is an error. Why?
    'hello'
    'C:\this has spaces\foo.txt'
    'another parameter'
    'wow so many parameters!'
    "-yak-type=$yak_type"
)
```

It's a little awkward, but I can deal with it.

After inspecting the [`Start-Process`] docs, we find that  `-ArgumentList` expects a `string[]`. Easy enough, any sane person would then try to do this:

```pwsh
Start-Process ... -ArgumentList $args
```

...but that doesn't work.

It substitutes `$args` with the first element of the array. The conniption induced by this behaviour
reminded me of POSIX shell. **Nothing** should remind me of POSIX shell.

How do we solve this? Well, if you'd read the docs properly you _utter buffoon_, you'd have noticed the [dedicated section](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-7.4#using-the-argumentlist-parameter) explaining this footgun. Here's what you're supposed to do:

```pwsh
Start-Process ... -ArgumentList (,$args)
```

> In this example, $args is wrapped in an array so that the entire array is passed to the script block as a single object.

Fantastic, I have to force Powershell to stop coercing the string array into a string.

### I have no args, and I must scream

None of the examples in the previous section involving `$args` work, I lied.
You see, I was simultaneously suffering through the two aforementioned and a third, secret issue!

Here is the error:

```
  10 |  [string[]]$args =  @(
     |  ~~~~~~~~~~~~~~~
     | Cannot assign automatic variable 'args' with type 'System.Object[]'
```

If you think this is an good example of error messages, you need to stop settling for less in life before it's too late. You matter, and you deserve better than this. <sup>[\[1\]]</sup>

My sanity is visibly and rapidly deteriorating; what's the problem this time‽ Well, you see, `$args` is a [reserved variable](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.4) that Powershell defines, and it contains the arguments passed to the script or function. You can mutate also `$args`. Also, `$args` is of type `System.Object[]`, likely to support non-string argument types via type erasure.

Why is `$args` in the global namespace? Why am I allowed to mutate it? Why does it use type erasure? Why is the error message so bad?

## Why are we still here? Just to suffer?

Throughout my experience with Powershell, I kept asking the same questions. Why was this made?
Why was this made _this_ way? What was happening that created the circumstances that that led to this
being made the way that it was made? [\[2\]]

In the future, I'd rather deal with the hassle of installing [`nushell`](https://www.nushell.sh/) on
every CI runner than put up with POSIX shell and Powershell, and I'd encourage you to do the same.

Powershell is not my favourite scripting language.[\[3\]]

["worse is better"]: https://en.wikipedia.org/wiki/Worse_is_better
[`Start-Process`]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process?view=powershell-7.4
[\[1\]]: https://youtube.com/clip/UgkxyeayQ81-ecG1lQPEL9NzBMjYE-vUOM85?si=U5aQdwM6iIDR7OQd
[\[2\]]: https://youtube.com/clip/UgkxZUlGRFYzFSMNqgPV54RjNEZWmxsPdMYO?si=Kx18qFwAg7rZH3zh
[\[3\]]: https://github.com/gco/xee/blob/4fa3a6d609dd72b8493e52a68f316f7a02903276/XeePhotoshopLoader.m#L108-L136C6
