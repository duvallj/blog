---
title: "You Won't Believe That Chrome Has Another Rendering Bug"
description: "Another foray into debugging a Chrome rendering bug, this time with extra platform-specific goodness!"
tags: daily thoughts, Chrome, Web
---

So in one of my [previous
posts](/posts/2023-12-28-i-think-i-found-a-webkit-bug.html), I outlined how
Chrome had a rendering bug where it did not properly mask anti-aliasing pixels
under certain complex CSS `mask` conditions. And wouldn't you know it, right as
I publish an [update](/posts/2024-03-15-working-around-a-webkit-bug.html) to
that post, I find yet _another_ Chrome rendering bug at work.

This story starts a couple months ago, when I'm working on a refresh of some of
the colors and layout of our app's main page to match a new design. The designer
comes up to me and says "ayo check out this weird bug I'm having", and shows me.

On his screen, many of the colors look darker than normal. And suddenly, when he
hovers over a specific UI element, all the colors snap back to normal. As soon
as he stops hovering, the colors go back to being weird again. I have never seen
this happen before We're all aware, though, I've been messing around in this
area recently, and I'm responsible for fixing it.

I take a look at his browser state in devtools, and discover something
distrubing: all the CSS is correct. Everything _is_ exactly the same as on my
machine. I've done nothing wrong, except fail to understand what the heck is
going on here.

To the best of my ability, here is a recreation of the bug I found:

<style>
  .outer.container {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding: 1rem;
    border: 1px solid black;
    opacity: 1;
  }
  .inner.container {
    display: grid;
    grid-template-rows: 1fr;
    grid-template-columns: 1fr 1fr;
    padding: 1rem;
    border: 1px solid blue;
    opacity: 1;
  }
  .inner.container:hover {
    border-color: red;
    backdrop-filter: blur(24px);
  }
  .background {
    grid-area: 1 / 1 / 2 / 3;
    background-color: rgba(0, 0, 0, 0.5);
  }
  img.round {
    grid-area: 1 / 1 / 2 / 2;
    width: 80px;
    aspect-ratio: 1 / 1;
    border-radius: 50%;
  }
  img.hidden {
    grid-area: 1 / 2 / 2 / 3;
    opacity: 0;
  }
</style>
<p>
<div class="outer container">
<div class="inner container">
<div class="background"></div>
<img class="round" src="/uploads/2024-03-20/dog.jpg">
<img class="round hidden" src="/uploads/2024-03-20/dog.jpg">
</div>
</div>
</p>

If you're in most browsers, the above demonstration does nothing for you. If, however, you're:

- using Chrome
- on MacOS
- on an XDR-enabled display

Then the above demonstration should make it so that hovering the container makes
the background color change, instead of just the border color changing.

If you look at the source code for this demonstration, you'll notice a few
interesting things:

- All the `:hover` selector is doing is `border-color: red; backdrop-filter:
blur(24px);`.
- There is an image with `opacity: 0` just hanging around.
- TODO: other important stuff? I haven't gotten it yet with the above setup,
  needs more work...

## Narrowing Down A Culprit

One of my coworkers noticed this bug only occured for him when a certain
coworker was signed in with his test account. Wait, What? He also noticed that,
when the test account's profile picture showed up on screen, his display
backlight lit up more, which usually occurs when trying to display an HDR image.

Excited for a reproduction, I lauched the app on my own screen. The bug didn't
reproduce. Then, I recalled that the screen I usually test on might not be
HDR-compatible, so I dragged it to another monitor that was. And lo and behold,
I had a reproduction. Nervously, I opened up devtools, and unloaded the image
thought to be the culprit, and sure enough, the bug went away.

So! Something about HDR images, and whatever `div` setup we have going on is
causing trouble.

## Why Is That??

To answer this question completely, I would have to dive into Chromium
internals. Unfortunately, I am not that good at diving into Chromium internals,
so instead I just have a couple bug reports that might give some insight:

### HDR Was A Known Problem

[This bug](https://issues.chromium.org/issues/40114989) was the first relevant
result when I searched for something along the lines of "blur interacts weirdly
with HDR MacOS Chrome??". Back in Chrome M80, they had to disable HDR support
for MacOS because they "fall out of HDR mode if there are extra render passes",
like blur, "which looks bad."

Now, that bug is pretty old, and probably not entirely applicable to the version
of Chrome we have today, so I kept looking, and...

### HDR Still Is A Problem

[This next bug](https://issuetracker.google.com/issues/325133349) is much closer
to what I was seeing: an HDR image causing a background with opacity to render
incorrectly! The reproduction isn't exactly the same, but hey, close enough.

Now I am fairly certain it is a Chrome bug, and because I do not have the chops
to write a patch that fixes it at the source, I have to work around it.

## Take 1

My thinking:

> If opening a `div` with `blur` stops whatever's going on with the
> transparency, then just having a random 1x1 div in the corner of the screen
> should do the trick!

Sure enough, that did it! No more weird transparency rendering issues,
everything looks normal again, we're all happy yaaaaaaay :)

yeah. um. Remember the first bug? Turns out this trick _disables HDR entirely_,
which is not a good thing if your CEO likes to view HDR videos in his app and
can tell the difference.

## Take 2

> The problem is Transparent Colors. If I make the offending background colors
> Not Transparent, everything will be fine!

Yep! Turns out it's not too hard to hack together something with
[Color.js](https://colorjs.io) that roughly emulates what the transparent
blending would otherwise do. I got it so that even in a side-by-side comparison,
I could hardly tell the difference.

And that's that!! I've worked around yet another Chrome bug purely by contoring
the CSS into the correct shape, which is why they pay me the big bucks :)

Hope this was somewhat educational, see y'all next time!
