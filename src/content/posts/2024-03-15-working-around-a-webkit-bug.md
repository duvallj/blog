---
title: Working Around A Chrome Bug (And Other CSS Limitations)
description: "Solving my earlier problem by (ab)using inline SVG images to create masks, instead of CSS-native geometry"
tags: daily thoughts, Chrome, Web
---

In my [previous post](/posts/2023-12-28-i-think-i-found-a-webkit-bug.html)[^1], I covered how Chrome's `mask-image` support doesn't do any antialiasing for `radial-gradient`, and what that meant for making notification badge cutouts. In this post, I'll go over a different way of providing a `mask-image` that _does_ have antialiasing (in all browsers!), namely SVGs.

---

Recall that we left off with a mask that looked something like this:

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
  width: 100px;
  aspect-ratio: 1;
}

div.pfp {
  background-color: black;
}

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

That is, one that was a little chunky on the curved parts. This got me wondering: is it possible to do better?

As it turns out, yes!! Using an svg instead of a CSS geometry object works a lot better. In the work codebase, I wrote a fancy SVG generator that embeds things directly inline with `url('data:image/svg+xml;utf8,${svg}')`, because we already use a lot of templated CSS generated by JS, but for this demonstration I'll just be using regular urls:

```html
<style>
  .take4 .pfp {
    border-radius: 50%;
    mask-image: url("/uploads/2024-03-15/mask1.svg");
    /* This is used because it's a lot easier to generate complex SVGs that are black and white, instead of transparent and not transparent */
    mask-mode: luminance;
  }
</style>
```

<style>
.take4 .pfp {
  border-radius: 50%;
  mask-image: url('/uploads/2024-03-15/mask1.svg');
  mask-mode: luminance;
}
</style>
<div class="horiz">
  <div class="avatar take4">
    <img class="pfp" src="/uploads/randomlogo.png">
  </div>
  <div class="avatar take4">
    <div class="pfp"></div>
  </div>
</div>

Great!! Now, let's just slap our notification badge back on and... voilà!

```html
<style>
  .badge {
    font-variant-numeric: tabular-nums;
    border-radius: 14px;
    background-color: var(--color-orange);
    font-size: 16px;
    line-height: 16px;

    position: absolute;
    top: 6px;
    left: 66px;
    padding: 6px;
  }
</style>
<div class="avatar take4">
  <img class="pfp" src="/uploads/randomlogo.png" />
  <div class="badge">100</div>
</div>
```

<style>
 .badge {
  font-variant-numeric: tabular-nums;
  border-radius: 14px;
  background-color: var(--color-orange);
  font-size: 16px;
  line-height: 16px;

  position: absolute;
  top: 6px;
  left: 66px;
  padding: 6px;
}
</style>
<div class="horiz">
  <div class="avatar take4">
    <img class="pfp" src="/uploads/randomlogo.png">
    <div class="badge">100</div>
  </div>
  <div class="avatar take4">
    <div class="pfp"></div>
    <div class="badge">9001</div>
  </div>
</div>

Now, for the sake of the argument, just like last time, let's consider what happens if you want More Badges. And also, you want to have this be composable, so you can nest them. Well, then this happens:

```html
<style>
  .take5 {
    mask-image: url("/uploads/2024-03-15/mask2.svg");
    mask-mode: luminance;
  }
  .badge-lower {
    position: absolute;
    background-color: var(--color-green);
    width: 28px;
    height: 28px;
    bottom: 6px;
    right: 6px;
    border-radius: 50%;
  }
</style>
<div class="avatar take4">
  <div class="take5">
    <img class="pfp" src="/uploads/randomlogo.png" />
    <div class="badge">100</div>
  </div>
  <div class="badge-lower"></div>
</div>
```

<style>
  .take5 {
    mask-image: url('/uploads/2024-03-15/mask2.svg');
    mask-mode: luminance;
  }
  .badge-lower {
    position: absolute;
    background-color: var(--color-green);
    width: 28px;
    height: 28px;
    bottom: 6px;
    right: 6px;
    border-radius: 50%;
  }
</style>
<div class="horiz">
  <div class="avatar take4">
    <div class="take5">
      <img class="pfp" src="/uploads/randomlogo.png">
      <div class="badge">100</div>
    </div>
    <div class="badge-lower"></div>
  </div>
  <div class="avatar take4">
    <div class="take5">
      <div class="pfp"></div>
      <div class="badge">9001</div>
    </div>
    <div class="badge-lower"></div>
  </div>
</div>

Gah!! Suddenly, all the talk about `no-clip` and `no-repeat` from the last post comes rushing back. This is no longer any sort of Chrome bug I don't think, but rather just a way the CSS `mask` property is specified to behave.

Reading the [`mask` specification](https://developer.mozilla.org/en-US/docs/Web/CSS/mask) more thoughroughly, we begin to see a solution:

1. Use `no-repeat` and `no-clip` (obviously)
2. Explicitly set the `mask-position` and `mask-size` so it will only cover the part of the image we want
3. Combine it with another mask that does cover the whole image, using `mask-composite: exclude` to cut away at that mask.

Doing that, we come up with the following solution:

```html
<style>
  .take6 {
    mask:
      /* mask-image: */
      url("/uploads/2024-03-15/mask2-inverse.svg") /* mask-mode: */ luminance
        /* mask-composite: */ exclude /* mask-repeat: */ no-repeat
        /* mask-clip: */ no-clip /* mask-position: */ bottom left /
        /* mask-size: */ 100px 100px,
      linear-gradient(white, white) no-clip luminance;
  }
</style>
<div class="avatar take4">
  <div class="take6">
    <img class="pfp" src="/uploads/randomlogo.png" />
    <div class="badge">100</div>
  </div>
  <div class="badge-lower"></div>
</div>
```

<style>
  .take6 {
  mask:
    /* We're actually going to cut away at the lower mask, and need to use an inverted image */url("/uploads/2024-03-15/mask2-inverse.svg") luminance exclude
    /* mask-repeat and mask-clip properties, making it so we only mask one part */
    no-repeat no-clip
    /* position the mask and size it appropriately */
    bottom left / 100px 100px, linear-gradient(white, white) no-clip luminance;
}
</style>
<div class="horiz">
  <div class="avatar take4">
    <div class="take6">
      <img class="pfp" src="/uploads/randomlogo.png">
      <div class="badge">100</div>
    </div>
    <div class="badge-lower"></div>
  </div>
  <div class="avatar take4">
    <div class="take6">
      <div class="pfp"></div>
      <div class="badge">9001</div>
    </div>
    <div class="badge-lower"></div>
  </div>
</div>

And there you have it! Perfectly anti-aliased, composable masks for all your CSS masking needs.

---

I swear we're the only application I've seen that actually does something like this. Everywhere else I've looked either doesn't use a mask at all, or just sets a `border` color to fake a mask.

This is why I put in the work tho, to prove we're better than that. CSS allows us to do these things, so do them we shall!!

[^1]: oh no it's been very too long since that last post. I meant to get this out sooner but have been procrastinating with other projects in the meantime... figured that, while I was doing other work for my blog, I should at least write an article :P