+++
title = "Shell is not my favourite language"
date = "2024-07-14"

[taxonomies]
tags = ["rant", "powershell", "posix", "shell"]
+++

Powershell wasted 10 hours of my life, so I was compelled to write this self-therapy session
masquerading as a blog post.

Before you discount my experience as the inane ravings of a UNIX fanboy, please understand that you couldn't be further from the truth. I sincerely tried to be fair and gave Powershell as much benefit of the doubt as I could muster.

Disclaimer aside, let's begin the descent into madness.

<!-- more -->

## Why use shell scripts?

Generally, shell scripts are used when a task needs to be automated, but it's not worth pulling out
a "real" (see: time-consuming) programming language. Given this, it stands to reason that shell scripting languages should
be quick and easy to both learn and write. If it's easier to write a program
than it is to write a shell script, it's failed to serve its only purpose.

> Foreshadowing is a narrative device in which suggestions or warnings about events to come are dropped or planted.

## The veritable mess that is POSIX

POSIX shell is, like most things descending from UNIX, poorly designed and
incredibly unpleasant to use. Granted, once you've developed a mental model of how it works (via
abstract causality and pain), you _eventually_ learn how to kludge together scripts relatively quickly. That is to say, after you've received enough third-degree burns from
touching the proverbial hot-plate, you learn what is and is not a good idea.

Over time, you learn to work around (or simply avoid) its many warts, namely:
error-prone string handling and its compulsion to violate the [principle of least astonishment].
POSIX shell is proof that ["worse is better"] is real and we can't have nice things.
It's a glue used to create precarious and unholy software obelisks, the lingering shadow of undead relics 3 decades past their expiration date.

Did you know "bash" is short for "bourne again shell"? Personally, I would prefer if these shells
_stayed_ dead. Unfortunately, I'm lacking a weapon with sacred affinity, so I'll
have to settle for asking nicely.

{{
    figure(src="environmental storytelling.jpg", caption="Environmental storytelling",
    alt="A variant of the ancient Dead Space 'turn off vsync' meme. The protagonist, Isaac Clarke, stands in front a wall with 'set -euo pipefall' scrawled in blood.")
}}

### I want to get off Mister POSIX's Wild Ride

To prove how esoteric some of these "features" are, here's a test: how does POSIX shell implement
features such as constants (`true` and `false`) and comparing values?

Was your answer: [running a magic executable](https://github.com/bminor/bash/blob/f3b6bd19457e260b65d11f2712ec3da56cef463f/execute_cmd.c#L5589)?!

```
❯ which [
/bin/[

❯ which true
/usr/bin/true
```

You see, when you compare a value like this:

```sh
if [ -z "$foo" ]; then
#  ┬
#  ╰─── this accursed symbol is actually an executable
```

...the shell runs the executable literally called `[`. As I alluded to before, `[` is _actually_ an alias for `test`. On macOS, they are separate
executables, which checks out according to [POSIX][posix_test]:

> The `test` and `[` utilities may be implemented as a single linked utility which examines the basename of the zeroth command line argument to determine whether to behave as the test or `[` variant.

In any other context, this would be reviled as the affront to computing that it is. But since
it's in the standard, it flies under the radar. I have a feeling the reception would have been different if `shell.js` tried to pull this.

Also, I lied—they're only _sometimes_ executables! [As per POSIX](posix_builtin):

> An implementation may choose to make any utility a built-in.

...meaning in that case the utility code is included in the shell, removing the need
for said magic executables. Why? Why have _this_ many failure modes?! Who thought
this was a good idea? After wracking my brain, the _only_ justification for its
inclusion is _maybe_ to accommodate systems with so little storage
that splitting utilities into separate files would be convenient.

### Byte streams are the `Any` of UNIX

POSIX shell lets you combine multiple commands together to form a "pipeline". This is accomplished
by connecting the [`stdout`][stdout] stream of one program into the [`stdin`][stdin] stream of another.

```
❯ find . -type f | xargs ls
```

```
               ╭─ stdin         ╭─ stdin         ╭─ stdin
               │                │                │
  find ─┬───▶─┴─ xargs ─┬───▶─┴─ shell ─┬───▶─┴─ terminal
        │                │                │
stdout ─╯        stdout ─╯        stdout ─╯
```

In contrast, if I ran `cat` in a shell:
```
❯ cat
boop\n
boop
```
```
                 ╭─ stdin         ╭─ stdin       ╭─ stdin         ╭─ stdin
                 │                │              │                │
keyboard ─┬───▶─┴─ shell ─┬───▶─┴─ cat ─┬───▶─┴─ shell ─┬───▶─┴─ terminal
          │                │              │                │
  stdout ─╯        stdout ─╯      stdout ─╯        stdout ─╯
```

- `boop\n` is sent from my keyboard to `cat` via `stdin`
- `cat` forwards `stdin` to `stdout`
- my terminal is connected to `stdout`, so `boop` appears on my screen twice

This is incredibly powerful... in _theory_. In _practice_ it's a wilderness, because streams are unstructured.
You're not sending text through streams, you're sending bytes, since text would
imply encoding.

Do I mean encoding:
- in a text sense: are these bytes encoded in Windows-1250 or Shift JIS?
- in a data format sense: are these bytes JSON or MessagePack?

Both! In practice, lacking a standard for structuring data means relying on
guessing character encodings and ad-hoc conventions. Please enjoy this [colourful
account][locale] from an [MPV][mpv] maintainer regarding how POSIX handles locales. I
have a feeling POSIX is not their favourite standard.

> If you hear "plain-text" used unironically please scold the prepetrator on my behalf.
> Text is `(bytes, encoding)`, omitting encoding means you just have bytes. Thank you.

Here's our previous example again:

```
❯ : ls
╭───┬───────────────┬──────┬───────┬─────────────╮
│ # │     name      │ type │ size  │  modified   │
├───┼───────────────┼──────┼───────┼─────────────┤
│ 0 │ can't wake up │ file │ 666 B │ 2 hours ago │
╰───┴───────────────┴──────┴───────┴─────────────╯

❯ find . -type f | xargs ls -al
xargs: unmatched single quote; by default quotes are special to xargs unless you use the -0 option
```

As you can see, our pipeline breaks because the filename contains a quote. This is fine,
since filenames obviously _never_ contain quotes. Here's one solution, tell both
`find` and `xargs` to use an ASCII `NUL` byte as the delimiter:

```
❯ find . -type f -print0 | xargs -0 ls -al
-rw-r--r-- 1 opeik staff 666 Jul 17 21:48 "./can't wake up"
```

This is one of the _nicer_ solutions. I hope whatever you're piping `find` into supports
it, or you'll have to add _yet more_ slop to handle it!

### Sisyphean-oriented programming

Don't get me started about error handling. Praying nothing goes wrong is a better use of your time than
trying to wrangle any semblance of reliability from this cacophony of undercooked and mismatched ideas.
Unhandled errors don't stop the script. Pipelines mask errors by always returning the exit code of the last command.
Subshells are utterly broken. Evaluating undefined variables results in an empty string.

Do you know how to spot a ~~traumatised~~ experienced shell programmer? It's easy! A
word of power exists which, upon being spoken, will cause severe psyche damage to all
shell programmers in the vicinity.

> To set the mood, start playing [this background music][ash lake], then come back to this article.

### Infernal fortress of suffering

Okay, deep breaths... the word of power is "IFS". The IFS (internal field seperator) is
a value controlling how the shell handles word spliting.
The semantics are _insane_—an example is required to truly envision
the depravity contained within those three miserable letters.

Let's write a shell script that prints the size of all files in the current directory:

```sh
for FILE in *; do
    du -h $FILE
done
```

...and he's what our directory looks like:

```
❯ touch wake me up
❯ ls
╭───┬──────┬──────┬──────┬──────────────╮
│ # │ name │ type │ size │   modified   │
├───┼──────┼──────┼──────┼──────────────┤
│ 0 │ wake │ file │  3 B │ a minute ago │
│ 1 │ me   │ file │  6 B │ a minute ago │
│ 2 │ up   │ file │  9 B │ a minute ago │
╰───┴──────┴──────┴──────┴──────────────╯
```

> Readers with an understanding of POSIX shell have likely already begun involuntarily
> clenching. It's too late now, you have become victim to the shell.

Let's try running it!

```
❯ ../ifs.sh
4.0K    wake
4.0K    me
4.0K    up
```

Hmm... it _seems_ to work?

For no particular reason, let's add a filename containing _spaces_:

```
❯ touch "can't wake up"
❯ ls
╭───┬───────────────┬──────┬───────┬──────────╮
│ # │     name      │ type │ size  │ modified │
├───┼───────────────┼──────┼───────┼──────────┤
│ 0 │ can't wake up │ file │ 666 B │ now      │
╰───┴───────────────┴──────┴───────┴──────────╯

❯ ../ifs.sh
du: cannot access "can't": No such file or directory
du: cannot access 'wake': No such file or directory
du: cannot access 'up': No such file or directory
```

Oh no, it's busted. The workaround is to _always_ quote variables (and string literals).

```sh
for FILE in *; do
    du -h "$FILE"
done
```

```
❯ ../ifs.sh
4.0K    can't wake up
```

As for why, recall that IFS controls how word splitting is performed.
Given the [default IFS][default_ifs] `' \t\n'` (that's space, tab, newline),
`can't wake up` is being split into three words: `can't`, `wake`, `up`.
This happens transparently (often without the programmer realising),
and causes one filename to be treated _as if_ it was three. Have you ever wondered why
shell scripts often collapse like a bridge made of popsicle sticks when presented
with a file containing spaces? Now you know!

If you're truly unhinged, you can leverage the IFS to perform rudimentary parsing.
I would _strongly_ advise against it, take a minute to read through this incredibly well-written
[Stack Overflow answer][bash_tokenize_string] regarding how to tokenize strings.
Of the nine solutions
presented, eight were incorrect (that's 88.8%!), all in incredibly subtle ways.
Do you feel it now—the torment of being unable to accomplish basic programming tasks in shell scripts?
Are you beginning to understand _why_ this godforsaken tool makes me so irrationally upset?!


<!-- ## Section about how fucked quotes are -->
### The only winning move is not to play

I have spent an embarrassing amount of my life writing and
debugging POSIX shell scripts, yet it still _regularly_ surprises me, as if it's mocking me for
trying to comprehend it. At the time of writing, the [Bash Pitfalls] page listing "common mistakes
made by bash users" contains 64 (sixty-four) entries!

POSIX shell is not my favourite language.<sup>[\[1\]]</sup>

> Sometimes, foreshadowing can be relatively obvious.

## Introducing Powershell

This brings us to Powershell. In concept, I quite like Powershell; it seeks to be a shell
scripting language that doesn't make you reconsider your life choices.
Powershell was released in 2006, meaning it's equipped with almost 20(!) years of hindsight from POSIX
shell. Similar to POSIX shell, it provides little functionality by itself, but unlike POSIX shell,
it conveniently exposes existing .NET APIs removing much of wheel re-invention that goes on in POSIX shell scripts.

One _massive_ advantage Powershell has over POSIX shell is the shift away from unstructured byte streams. When
piping one command to another, structured .NET objects are passed instead. I cannot stress enough
how much of an improvement is, being forced to use byte streams makes me feel like neanderthal.

However, it is with regret, my dear reader, that I inform you Powershell is just as bad in a variety
of new and exciting ways. The rest of the post details my first-time user experience with Powershell.

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

I wasn't able to get either line break methods working, so let's sidestep this nonsense
by defining the arguments beforehand.

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

After inspecting the [`Start-Process`] docs, we find that  `-ArgumentList` expects a `string[]`.
Luckily for us, `args` is also a `string[]`! Given our variable and the parameter
have _the same type_, any sane person would expect this to work:

```powershell
Start-Process -ArgumentList $args # ...
```

...but it doesn't work.

Worse still, the command _succeeds_ but behaves like you don't expect: it
substitutes `$args` with the first element of the array.
The conniption induced by this behaviour
made me vividly recall my past POSIX shell trauma, which is _generally_ something to
be avoided when designing software.

How do we solve this? Well, if you'd read the docs properly you _utter buffoon_, you'd have noticed the [dedicated section](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-7.4#using-the-argumentlist-parameter) explaining this footgun. Here's what you're _supposed_ to do:

```powershell
Start-Process ... -ArgumentList (,$args)
```

> In this example, `$args` is wrapped in an array so that the entire array is passed to the script block as a single object.

<!-- Powershell takes all that -->

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

I have nothing to add, this should speak for itself. Next section!

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
[principle of least astonishment]: https://en.wikipedia.org/wiki/Principle_of_least_astonishment

[posix_test]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/test.html
[posix_builtin]: https://pubs.opengroup.org/onlinepubs/009604599/utilities/xcu_chap02.html#tag_02_14
[bash_test]: https://github.com/coreutils/coreutils/blob/74ef0ac8a56b36ed3d0277c3876fefcbf434d0b6/src/test.c
[ash lake]: https://soundcloud.com/argash/dark-souls-ost-the-ancient-dragon-extended
[default_ifs]: https://pubs.opengroup.org/onlinepubs/009695399/utilities/xcu_chap02.html#tag_02_05_03
[bash_tokenize_string]: https://stackoverflow.com/questions/10586153/how-to-split-a-string-into-an-array-in-bash/45201229#45201229
[stdin]: https://en.wikipedia.org/wiki/Standard_streams#Standard_input_(stdin)
[stdout]: https://en.wikipedia.org/wiki/Standard_streams#Standard_output_(stdout)
[locale]: https://github.com/mpv-player/mpv/commit/1e70e82baa9193f6f027338b0fab0f5078971fbe
[mpv]: https://github.com/mpv-player/mpv


[\[1\]]: https://github.com/gco/xee/blob/4fa3a6d609dd72b8493e52a68f316f7a02903276/XeePhotoshopLoader.m#L108-L136C6

[\[2\]]: https://stackoverflow.com/a/8762068

[\[3\]]: https://youtube.com/clip/UgkxyeayQ81-ecG1lQPEL9NzBMjYE-vUOM85?si=U5aQdwM6iIDR7OQd

[\[4\]]: https://youtube.com/clip/UgkxZUlGRFYzFSMNqgPV54RjNEZWmxsPdMYO?si=Kx18qFwAg7rZH3zh
