# Factory

3D slide decks are so 2011. We need stuff that's _actually_ new and useful, such as:

* In-browser slide editing with markdown.
* Serve your presentation straight from your browser. No more remote web servers, no deploys.
* Tablet friendliness. Because I want to create a slide deck from my phone
as bad as I want to stab myself in the eye with a rusty spoon.

# Messing with the codes

I've put together a ghetto dev suite using Rake (sue me, parallel tasks in the shell are hard) which compiles SASS/CoffeeScript and runs a local HTTP/WebSocket server, which happens to be the same server that will run in the app's domain. Check the `gems` file for a list of the gems you'll need. No need for Bundler is good, right?

# Author

Brought to you with much love by [@julio_ody](http://twitter.com/julio_ody).

# License

MIT.

# Inspiration

The idea for this app came out of two things: the fact I found myself not willing to get a slide deck going with the usual browser deck tools that are around (read: roll an HTML doc, hook the lib in, write each slide in HTML), because lazy.

And from seeing [socrates.io][http://socrates.io] nailing a really good UI for writing in browser.
