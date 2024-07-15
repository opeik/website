+++
title = "Shell is not my favourite language"
date = "2024-07-14"

[taxonomies]
tags = ["rant", "powershell", "posix", "shell"]
+++

Powershell wasted 10 hours of my life, so I was compelled to write this self-therapy session
masquerading as a blog post.

Before you discount this as the ravings of a UNIX fanboy, please understand that you couldn't
be further from the truth. I sincerely tried to be fair and gave Powershell as much benefit of the
doubt as I could muster.

Disclaimer aside, let's begin the descent into madness.

<!-- more -->

## Why use shell scripts?

Generally, shell scripts are used when a task needs to be automated, but it's not worth pulling out
a "real" (see: time-consuming) programming language. Given this, it stands to reason that shell scripting languages should
be quick to learn and easy to write. If it's easier to write a program
than it is to write a shell script, it's failed to serve its only purpose.

> Foreshadowing is a narrative device in which suggestions or warnings about events to come are dropped or planted.

## The veritable mess that is POSIX

POSIX shell is, like most things descending from UNIX, poorly designed and
incredibly unpleasant to use. Granted, once you've developed a mental model of how it works (via
abstract causality and pain), you learn _eventually_ how to kludge together scripts relatively quickly. It has many warts, though, namely: inconsistency, error-prone string handling, and its
compulsion to violate the principle of least surprise.

POSIX shell is a concrete example of ["worse is better"] in action. It's a glue used to create
precarious and unholy software obelisks, the undying remnants of bygone relics 5 decades past their
expiration date.

### I want to get off Mister POSIX's Wild Ride

To prove how esoteric some of this knowledge is, here's a test: how does POSIX shell implement
features such as constants (`true` and `false`) and comparing values?

Was your answer: [running a magic executable](https://github.com/bminor/bash/blob/f3b6bd19457e260b65d11f2712ec3da56cef463f/execute_cmd.c#L5589)?!

[Control flow](https://github.com/coreutils/coreutils/blob/74ef0ac8a56b36ed3d0277c3876fefcbf434d0b6/src/test.c)?

```
❯ which [
/bin/[
```

[Constants](https://github.com/coreutils/coreutils/blob/74ef0ac8a56b36ed3d0277c3876fefcbf434d0b6/src/true.c)?

```
❯ which true
/usr/bin/true
```

They're both executables! But only sometimes! As per the specification,
all ["utilities"](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_01)
may be ["built-in"](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14),
meaning the code is included in the shell, removing the need for the magic executables.

{{ figure(path="environmental storytelling.jpg", caption="Environmental storytelling") }}

Don't get me started on error handling. Praying nothing goes wrong is a better use of your time than
trying to wrangle any semblance of reliability from this cacophony of undercooked and mismatched ideas.
Unhandled errors don't stop the script. Pipelines mask errors by always returning the exit code of the last command.
Subshells are utterly broken. Evaluating undefined variables results in an empty string.

Furthermore, lacking a standard for structuring data means relying on ad-hoc conventions, such as
`find`'s `-print0` parameter, which separates results by an ASCII `NUL` character. I hope
whatever you're piping `find` into supports this, or you'll have to add _yet more_ slop
to handle it!

I have spent an embarrassing amount of my life writing and
debugging POSIX shell scripts, yet it still _regularly_ surprises me, as if it's mocking me for
trying to comprehend it. At the time of writing, the [Bash Pitfalls] page listing "common mistakes
made by bash users" contains 64 (sixty-four) entries!

POSIX shell is not my favourite language.<sup>[\[1\]]</sup>

> Sometimes, foreshadowing can be relatively obvious.

## Introducing Powershell

This brings us to Powershell. In concept, I quite like Powershell. Equipped with several
decades of hindsight, it seeks to be a shell scripting language that doesn't make you reconsider your
life choices.

It is with regret, my dear reader, that I inform you Powershell is just as bad in a variety of new and exciting ways.
The rest of the post details my first-time user experience with Powershell.

### Running a program

Do you know what shell scripts frequently do? Run programs. They run other programs.

To run programs in Powershell, you can either:

1) run it [directly](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/running-commands?view=powershell-7.4#running-native-commands)
2) use the [call operator](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.4#call-operator-)
3) or, use [`Start-Process`]

Let's do it the "Powershell way" and use [`Start-Process`]:

```powershell
Start-Process -Wait -FilePath 'my\amazing\custom\app.exe' -ArgumentList 'hello' 'C:\this has spaces\foo.txt' 'another parameter' 'wow so many parameters!' "-yak-type=$yak_type"
```

### Wait, how do I break this line?

Hmm, this line is getting rather long. Now that I think about it, all the examples I see of Powershell code run off the page... I wonder why?

Anyway, let's make this more legible by splitting the command over multiple lines.

To split lines in Powershell, you can either:

1) use a backtick:
    ```powershell
    # The space before the backtick is required. Why?
    Get-ChildItem -Recurse `
        -Filter *.jpg
    ```
2) use a pipe:
    ```powershell
    Get-ChildItem |
        Select Name,Length
    ```

Oh, by the way, both methods are [finnicky](https://stackoverflow.com/a/53575932) and prone to [breaking code](https://devblogs.microsoft.com/scripting/powershell-code-breaks-break-line-not-code/).

### Wait, why's my array being coerced?

Let's sidestep this nonsense by defining the arguments beforehand.

```powershell
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

```powershell
Start-Process ... -ArgumentList $args
```

...but that doesn't work.

It substitutes `$args` with the first element of the array. The conniption induced by this behaviour
reminded me of POSIX shell. **Nothing** should remind me of POSIX shell.

How do we solve this? Well, if you'd read the docs properly you _utter buffoon_, you'd have noticed the [dedicated section](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-7.4#using-the-argumentlist-parameter) explaining this footgun. Here's what you're supposed to do:

```powershell
Start-Process ... -ArgumentList (,$args)
```

> In this example, `$args` is wrapped in an array so that the entire array is passed to the script block as a single object.

### Wait, where's my output?

If you run a program via [`Start-Process`], you won't get any output in your terminal. Here's what you're _supposed_ to do:<sup>[\[2\]]</sup>

```powershell
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "ping.exe"
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false
$pinfo.Arguments = "localhost"
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"
Write-Host "exit code: " + $p.ExitCode
```

Next section!

### Wait, why doesn't anything work?

The examples in the previous section involving `$args` don't work, I lied.
You see, I was simultaneously suffering through the two aforementioned issues and a third, secret issue!

Here's the error:

```
  10 |  [string[]]$args =  @(
     |  ~~~~~~~~~~~~~~~
     | Cannot assign automatic variable 'args' with type 'System.Object[]'
```

If you think this is an good example of error messages, you need to stop settling for less in life before it's too late. You matter, and you deserve better than this.<sup>[\[3\]]</sup>

My sanity is rapidly deteriorating; what's the problem this time?! Well, you see, `$args` is an ["automatic variable"](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.4) that Powershell defines, and it contains the arguments passed to the script or function, obviously!

Why is `$args` in the global namespace? Why am I allowed to mutate it? Why does it use type erasure?
Why is this error message so bad?

## Closing thoughts

Throughout this ordeal, I kept asking the same question: why?

Why was this made? Why was this made _this_ way? What was happening that created the circumstances that led to this
being made the way that it was made?<sup>[\[4\]]</sup>

In the future, I'd rather deal with the hassle of installing [`nushell`] on every CI runner
than continue to subject myself to the depraved machinations of POSIX shell and Powershell.
I encourage you to do the same, we all deserve better.

Powershell is not my favourite language.<sup>[\[1\]]</sup>

["worse is better"]: https://en.wikipedia.org/wiki/Worse_is_better
[`Start-Process`]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process?view=powershell-7.4
[`nushell`]: https://www.nushell.sh/
[Bash Pitfalls]: https://mywiki.wooledge.org/BashPitfalls


[\[1\]]: https://github.com/gco/xee/blob/4fa3a6d609dd72b8493e52a68f316f7a02903276/XeePhotoshopLoader.m#L108-L136C6

[\[2\]]: https://stackoverflow.com/a/8762068

[\[3\]]: https://youtube.com/clip/UgkxyeayQ81-ecG1lQPEL9NzBMjYE-vUOM85?si=U5aQdwM6iIDR7OQd

[\[4\]]: https://youtube.com/clip/UgkxZUlGRFYzFSMNqgPV54RjNEZWmxsPdMYO?si=Kx18qFwAg7rZH3zh
