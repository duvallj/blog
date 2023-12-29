---
title: I Think I Found A WebKit Bug
description: "In which I go over how different values of `mask` can behave differently, despite intending for them to do the same thing. Shows off some of what I've learned in my job doing web development"
tags: daily thoughts, WebKit, Web
---

At work, I'm in between a few big projects, spending my time polishing the UI
so it shines. One of those polish items has been to revamp how we do
notification badges, and through that, I think I discovered a WebKit bug.

---

The simplest way to do a notification badge is like this:

<style>
.horiz {
  display: flex;
  gap: 2rem;
}

.avatar {
  position: relative;
  width: fit-content;
  margin: 2rem 0;
}

.avatar .pfp {
  width: 80px;
  aspect-ratio: 1;
}

.take0 .pfp {
  border-radius: 50%;
}

div.pfp {
  background-color: black;
}

.badge {
  font-variant-numeric: tabular-nums;
  border-radius: 50%;
  background-color: var(--color-orange);
  line-height: 1em;
}

.take0 .badge {
  position: absolute;
  top: 0;
  right: 0;
  padding: 0.25rem 0.5rem;
}

</style>
<div class="horiz">
<div class="avatar take0">
  <img class="pfp" src="/uploads/randomlogo.png" />
  <div class="badge">1</div>
</div>
<div class="avatar take0">
  <div class="pfp"></div>
  <div class="badge">2</div>
</div>
</div>

Nice 'n easy! Just slap a `position: absolute` inside a `position: relative`
and everything's pretty much good-to-go. The only downside to this is that is
doesn't *quite* look professional enough. A neat little detail to have is a
little transparent space between the profile picture and the thing going on top
of it, like in Discord.

Now, you *can* just fake this effect by slapping on a `border: 5px solid
var(--background-color)` onto the the thing, but if the background color ever
changes you have to animate this `border` property with the same curves, so for
separation of concerns it's just easier[^1] to have the image be truly
transparent in that area.

So! Let's try to do exactly that. A quick dive into what exists out there in
general brings up the
[mask](https://developer.mozilla.org/en-US/docs/Web/CSS/mask) property, with a
specially crafted
[radial-gradient](https://developer.mozilla.org/en-US/docs/Web/CSS/gradient/radial-gradient)
as the mask source. Let's see how this looks, first without the indicator:

```html
<style>
/* irrelevant properties omitted for brevity */
.take1 .pfp {
  border-radius: 50%;
  mask-image: radial-gradient(ellipse 20% 20% at 85% 85%, transparent 99%, white 100%);
}
</style>

<div class="avatar take1">
  <img class="pfp" src="/uploads/randomlogo.png" />
</div>
```

<style>
.take1 .pfp {
  border-radius: 40px;
  mask-image: radial-gradient(ellipse 20% 20% at 85% 85%, transparent 99%, white 100%);
}
</style>
<div class="horiz">
  <div class="avatar take1">
    <img class="pfp" src="/uploads/randomlogo.png" />
  </div>
  <div class="avatar take1">
    <div class="pfp"></div>
  </div>
</div>

Interesting!! What this is doing, effectively, is drawing a completely
transparent circle at a specified location within the bounding box, using a
`transparent 99%` and `white 100%` stop to effectively get a hard line instead
of a gradient.

Unfortunately, this approach is not without problems.

## Problem 1: It Looks Chunky

This becomes more apparent when we try to add the dot:
```html
<style>
.indicator {
  aspect-ratio: 1;
  border-radius: 50%;
}

.take1 .indicator {
  width: 30px;
  position: absolute;
  bottom: -3.5px;
  right: -3.5px;
}
</style>
<div class="avatar take1">
  <img class="pfp" src="/uploads/randomlogo.png" />
  <div class="indicator green"></div>
</div>
```

<style>
.indicator {
  aspect-ratio: 1;
  border-radius: 50%;
}

.take1 .indicator {
  width: 30px;
  position: absolute;
  bottom: -3.5px;
  right: -3.5px;
}

.green {
  background-color: var(--color-green);
}
</style>
<div class="horiz">
  <div class="avatar take1">
    <img class="pfp" src="/uploads/randomlogo.png" />
    <div class="indicator green"></div>
  </div>
  <div class="avatar take1">
    <div class="pfp"></div>
    <div class="indicator green"></div>
  </div>
</div>

Now, we can more clearly see that the masked-out part is ***not anti-aliased***, unlike the circular borders of the profile picture and indicator. This is part of the bug I'm referring to in the post title.

## Problem 2: It Clips
Things get worse if we try to add a second indicator (and not just from a
design perspective, lol).
```html
<style>
.take2 .pfp {
  mask-image: radial-gradient(ellipse 20% 20% at 85% 85%, transparent 99%, white 100%);
}

.take2 img {
  border-radius: 50%;
}

.take2 .indicator {
  width: 30px;
  position: absolute;
}

.take2 .indicator1 {
  bottom: -3.5px;
  right: -3.5px;
}

.take2 .indicator2 {
  top: -3.5px;
  left: -3.5px;
}

</style>

<div class="avatar take2">
  <div class="pfp">
    <img src="/uploads/randomlogo.png" />
    <div class="indicator indicator2 orange"></div>
  </div>
  <div class="indicator indicator1 green"></div>
</div>
```

<style>
.orange {
  background-color: var(--color-orange);
}

.take2 .pfp {
  mask-image: radial-gradient(ellipse 20% 20% at 85% 85%, transparent 99%, white 100%);
  background-color: transparent;
}

.take2 img {
  border-radius: 50%;
}

.take2 .img {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background-color: black;
}

.take2 .indicator {
  width: 30px;
  position: absolute;
}

.take2 .indicator1 {
  bottom: -3.5px;
  right: -3.5px;
}

.take2 .indicator2 {
  top: -3.5px;
  left: -3.5px;
}
</style>
<div class="horiz">
  <div class="avatar take2">
    <div class="pfp">
      <img src="/uploads/randomlogo.png" />
      <div class="indicator indicator2 orange"></div>
    </div>
    <div class="indicator indicator1 green"></div>
  </div>
  <div class="avatar take2">
    <div class="pfp">
      <div class="img"></div>
      <div class="indicator indicator2 orange"></div>
    </div>
    <div class="indicator indicator1 green"></div>
  </div>
</div>

Huh?? You may have many questions, such as "why not just put
`class="indicator2"` outside the part that clips?" and "wait hold on why is is
clipping like that in the first place?" The answers to which are:

1. React Component Hierarchy[^2]: it's simpler to make a component that says "I
   want to optionally add exactly one new indicator" on something than so say
   "I want to add a configurable number of indicators with variable
   positions", because otherwise you have to somehow blend the masks which can
   get hairy[^3].
2. We're Getting To That

It may have been wiser to bite the bullet and figure out how to reorganize the
component hierarchy, but now I was curious to get to the bottom of this and
figure out if I could do something about the first problem at the same time.

Poking around in developer tools, we can confirm that it's *just* the `mask`
property causing this clipping. With the mask on, affecting the bottom right
corner, we suddenly get clipping in the top left. A panicked search for "mask
clips things that it shouldn't" brings us to the
[mask-clip](https://developer.mozilla.org/en-US/docs/Web/CSS/mask-clip)
property. Swell! Let's just specify `no-clip` then, and:

<style>
.noclip {
  mask-clip: no-clip;
}
</style>
<div class="horiz">
  <div class="avatar take2">
    <div class="pfp noclip">
      <img src="/uploads/randomlogo.png" />
      <div class="indicator indicator2 orange"></div>
    </div>
    <div class="indicator indicator1 green"></div>
  </div>
  <div class="avatar take2">
    <div class="pfp noclip">
      <div class="img"></div>
      <div class="indicator indicator2 orange"></div>
    </div>
    <div class="indicator indicator1 green"></div>
  </div>
</div>

Great!! Seems we're done then, no? Ignoring the slight imperfection in the
mask, of course. Well, if we happen to move `.indicator2` to the right side, then...

```html
<style>
.take2 .indicator3 {
  top: -3.5px;
  right: -3.5px;
}
</style>

<div class="avatar take2">
  <div class="pfp noclip">
    <img src="/uploads/randomlogo.png" />
    <div class="indicator indicator3 orange"></div>
  </div>
  <div class="indicator indicator1 green"></div>
</div>
```

<style>
.take2 .indicator3 {
  top: -3.5px;
  right: -3.5px;
}
</style>
<div class="horiz">
  <div class="avatar take2">
    <div class="pfp noclip">
      <img src="/uploads/randomlogo.png" />
      <div class="indicator indicator3 orange"></div>
    </div>
    <div class="indicator indicator1 green"></div>
  </div>
  <div class="avatar take2">
    <div class="pfp noclip">
      <div class="img"></div>
      <div class="indicator indicator3 orange"></div>
    </div>
    <div class="indicator indicator1 green"></div>
  </div>
</div>


HUH. WHAT. That's strange, to say the least. All we did was change `left:
-3.5px` to `right: -3.5px` and suddenly the top is shorn off?? Playing around a
bit more and setting `right: 10px`, we see a clue:

<style>
.take2 .indicator4 {
  top: -3.5px;
  right: 10px;
}
</style>
<div class="horiz">
  <div class="avatar take2">
    <div class="pfp noclip">
      <img src="/uploads/randomlogo.png" />
      <div class="indicator indicator4 orange"></div>
    </div>
    <div class="indicator indicator1 green"></div>
  </div>
  <div class="avatar take2">
    <div class="pfp noclip">
      <div class="img"></div>
      <div class="indicator indicator4 orange"></div>
    </div>
    <div class="indicator indicator1 green"></div>
  </div>
</div>

That indentation in where it gets cut off is suspicious.. it's almost like...

### The Mask Is Repeating
That is, when the content goes outside the bounding box, a duplicate copy of
the mask is placed there. Skimming the sidebar of the MDN tab where we found
mask-clip, we do indeed see there is a
[mask-repeat](https://developer.mozilla.org/en-US/docs/Web/CSS/mask-repeat)
property, whose default value implies this exact behavior. Attempting to set
`no-repeat` on the mask, however, just results in it clipping again.

## Problem 3: It's Problem 1 Again, But Different
The designer comes back and says "that indicator in the top right is actually
meant to be an unread message count, and should have a pill-shaped mask." OK,
no problem, some reading of MDN has us come across the
[mask-composite](https://developer.mozilla.org/en-US/docs/Web/CSS/mask-composite)
property, and a bit of fooling around with it later we have a prototype:

```html
<style>
.take3 .pfp {
  border-radius: 50%;
  mask-image: radial-gradient(ellipse 20% 20% at 80% 20%, transparent 99%, white 100%), linear-gradient(to bottom, white 40%, transparent 41%), linear-gradient(to left, transparent 19%, white 20%);
  mask-composite: subtract;
}
</style>
<div class="avatar take3">
  <img class="pfp" src="/uploads/randomlogo.png"></div>
</div>
```
<style>
.take3 .pfp {
  border-radius: 50%;
  mask-image: radial-gradient(ellipse 20% 20% at 80% 20%, transparent 99%, white 100%), linear-gradient(to bottom, white 40%, transparent 41%), linear-gradient(to left, transparent 19%, white 20%);
  mask-composite: subtract;
}
</style>
<div class="horiz">
  <div class="avatar take3">
    <img class="pfp" src="/uploads/randomlogo.png">
  </div>
  <div class="avatar take3">
    <div class="pfp"></div>
  </div>
</div>

I could not honestly tell you how this works, only that it does. But as you can
see from this image (and maybe even on your browser!), there's a huge problem:
not only is the circular part of the mask not anti-aliased, but ***it's not
even masking the anti-aliased pixels from the `border-radius`***. This is the
clearest demonstration of the WebKit bug I was promising to expose in this
post, so here you go :)

## A Better(?) Approach
Fortunately, that same day I found this bug I also came up with an approach
that solves all of these problems, at a small cost to generated code size. But
this post is long enough as it is already, and you're probably fatigued reading
this, so I think I'll leave that for a follow-up post.

As an aside, Markdown is really nice for things like this. I can just include
HTML right in with the rest of the formatted text and it just works?? Magical.

[^1]: You've read the rest of the post. You know this isn't actually easy.
[^2]: Yes, we ship a React.js Electron app. Yes, the performance is much of a
    problem as you think it is. I will not be taking any questions about this.
[^3]: As if I didn't end up writing something like that anyways, lol
