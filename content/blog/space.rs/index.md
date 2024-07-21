+++
title = "space.rs"
description = "Ferris go space."
date = "2022-01-27"

[taxonomies]
tags = ["rust"]
+++

Memory safety: the final frontier

<div id="banner">
  <img id="ferris" src="/blog/space-rs/ferris.svg">
  <div id="stars"></div>
</div>

<style type="text/css" rel="stylesheet">
:root {
  --banner-height: calc(50px + 10vh);
}

#banner {
  position: relative;
  width: 100%;
  height: var(--banner-height);
  background: radial-gradient(ellipse at bottom, #1b2735 0%, #090a0f 100%);
  overflow: hidden;
}

#stars {
  position: absolute;
  width: 100%;
  height: 100%;
}

#ferris {
  position: absolute;
  height: calc(30px + 2.5vh);
  left: -50%;
  top: -50%;
  z-index: 1;
}

.star {
  position: absolute;
  animation: linear infinite star-parallax;
  background: white;
  border-radius: 50px;
}

.star-size-1 {
  width: 1px;
  height: 1px;
}

.star-size-2 {
  width: 2px;
  height: 2px;
}

.star-size-3 {
  width: 3px;
  height: 3px;
}

@keyframes star-parallax {
  from { transform: translateY(0px); }
  to { transform: translateY(calc(var(--banner-height) * -1)); }
}
</style>

<script>
let lastKeyframe
const stars = document.querySelector("#stars")

const star = {
  min: {
    left: 1,
    top: 1,
    duration: 10,
  },
  max: {
    left: 99,
    top: 99,
    duration: 50,
  }
}

const ferris = {
  element: document.querySelector("#ferris"),
  min: {
    left: 1,
    top: 1,
    duration: 10000,
  },
  max: {
    left: 99,
    top: 99,
    duration: 20000,
  }
}

const keyframes = [
  {
    from: { top: "-50%", left: "-50%", rotation: "-60deg" },
    to: { top: "150%", left: "150%", rotation: "40deg" }
  },
  {
    from: { top: "100%", left: "150%", rotation: "20deg" },
    to: { top: "25%", left: "-50%", rotation: "-80deg" }
  },
  {
    from: { top: "-100%", left: "100%", rotation: "-35deg" },
    to: { top: "200%", left: "0%", rotation: "-135deg" }
  },
  {
    from: { top: "200%", left: "15%", rotation: "90deg" },
    to: { top: "-100%", left: "85%", rotation: "270deg" }
  },
  {
    from: { top: "75%", left: "-50%", rotation: "90deg" },
    to: { top: "25%", left: "150%", rotation: "190deg" }
  },
  {
    from: { top: "25%", left: "150%", rotation: "70deg" },
    to: { top: "75%", left: "-50%", rotation: "170deg" }
  }
]

function random(min, max) {
  return Math.floor(Math.random() * (max - min) + min)
}

function makeStars(type, quantity) {
  for (let i = 0; i < quantity; ++i) {
    const left = random(star.min.left, star.max.left)
    const top = random(star.min.top, star.max.top)
    const duration = random(star.min.duration, star.max.duration)

    // Make a duplicate star offset by the banner height for seamless vertical scrolling.
    for (let j = 0; j < 2; ++j) {
      let star = document.createElement("div")
      star.classList.add("star", `star-size-${type}`)
      star.style.left = `${left}%`
      star.style.top = `${top + (j * 100)}%`
      star.style.animationDuration = `${duration}s`
      stars.appendChild(star)
    }
  }
}

function randomizeFerrisTrajectory() {
  let keyframe
  do {
    keyframe = keyframes[random(1, keyframes.length)]
  } while (keyframe === lastKeyframe)
  lastKeyframe = keyframe

  let animation = ferris.element.animate([
    {
        top: `${keyframe.from.top}`, left: `${keyframe.from.left}`,
        transform: `translate(-50%, -50%) rotate(${keyframe.from.rotation})`,
    },
    {
        top: `${keyframe.to.top}`, left: `${keyframe.to.left}`,
        transform: `translate(-50%, -50%) rotate(${keyframe.to.rotation}`,
    }
  ],
  { duration: random(ferris.min.duration, ferris.max.duration), })
  .onfinish = () => randomizeFerrisTrajectory()
}

makeStars(1, 70) // Small stars
makeStars(2, 10) // Normal stars
makeStars(3, 5)  // Large stars
randomizeFerrisTrajectory()
</script>

At approximately `2021-12-22T23:46:00Z`, a Rust app I developed was successfully uploaded and executed on a satellite.
To the best of my knowledge, this is one of the first instances of Rust in space.
While I never expected to be working in the aerospace industry, I'm excited to be bringing Rust to the cutting edge.
