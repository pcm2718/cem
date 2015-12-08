# cem
&lt;cem> ::= "chrome is an emacs mode" | &lt;cem> "is an emacs mode"

## About

The central idea behind cem is that Chrome's primary evolutionary pressure is to become a better web browser, more specifically a better web page renderer; peripheral features, such as bookmarks and history, simply don't receive as much attention. Chrome by and large adheres to the Unix Philosophy ("do one thing well"), which is a *good thing*, but leaves certain areas lacking.

One area that bothered me specifically was tab management, beyond ~20 tabs in a window management starts to get annoying, beyond ~50 tabs per window management becomes impossible. In addition, I found I frequently wanted to have only some specific set of tabs open to avoid excessive resource usage, or to reduce clutter. I also found that I wanted to be able to pick up where I left off through a hard system restart without having to deal with Chrome's finnicky "Continue where you left off" option.

These wants lead me to the Tabs Outliner extension for Chrome. Tabs Outliner has worked pretty well so far, but it has a few shortcomings which bother me, like the lack of keyboard shortcuts or a "search within folded" function (within the free version, I cannot speak for the paid premium version).

I initially considered modifying the extention to support these features, but I noticed it suggested a similarity to org-mode and the idea came to me to implement a sort of Emacs mode in imitiation of Tabs Outliner, being able to take advantage of Emacs's strengths for what can be mostly reduced to a text editing problem.

cem is then intended for people who would like a way to compliment Chrome's strengths in web browsing with Emacs's proven strengths as an outliner and as a text editor in general. This makes Chrome a sort of pseudo-mode for Emacs, just with comparatively poor scripting and implemented as a monolith of C++.

## Thanks

A special thanks goes to the Chromi Chrome extention (https://github.com/smblott-github/chromi) and friends, without whom the project may never have gotten off the ground. Another special thanks goes to Tabs Outliner, which gave me the UI and unifying idea for the project. I wish their maintainers and developers the best of luck.

pcm2718
