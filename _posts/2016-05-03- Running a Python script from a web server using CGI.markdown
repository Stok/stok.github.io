---
layout: post
title:  "Running a Python script on a web server using CGI"
date:   2016-05-03 17:00:00 +0100
categories: Projects
---

In a previous [post], I presented a Python script for scraping some data off of a website. I then put that script on an AWS micro-instance. Here are some of the details on getting the server bit up and running. Disclaimer: I'd never done this before, and many of the concepts are new to me. Be prepared for some lack of clarity and a good dose of bullshit. 

The [common gateway interface (CGI)] is used to create dynamic websites. Looking at examples on how this works, I gather that the server is told to run a specific interpreter (python, say) on a script (kept server-side). The script can be made to respond with some html that the server can display as the result. I'm not too sure about how this gets done. I just figured out how to set it up.

On the python side, I need to tell it to load the CGI support library:

{% highlight python %}
import cgi, cgitb #this second one is a debugger. To be enabled with cgitb.enable()
{% endhighlight %}

I think these libraries are usually installed by default. If they don't, I'm sure you can easily get them using your favorite package manager (pip, anaconda...). Documentation on the library can be found [here]. 

The basic idea is: once you load the library, the stdout of the script points to the target webpage.
So I wrote a whole bunch of print() calls to 'create' a page showing the result I wanted:

{%highlight python%}

print("<html><head><meta content='text/html; charset=UTF-8' />")
print("<title>Calculatrice Missions</title>")
print("</head>")
print("<body>")
print("<div>Vous avez indique que la mission a  " + country_code + "  se deroulera durant les dates suivants : %s </div> " % list(map(lambda x : x.strftime('%d/%m/%Y'), result[0])))
	.
	.
	.
print("<div>Le montant plafonne est : %s</div>" % result[7])
print("<div>Calcul termine. Bonne journee!</div>")
print("</body>")
print("</html>")

{%endhighlight%}

A quirky thing: you need to start the web page with:

{% highlight python %}
print("Content-type:text/html\n\n")
print("")
{%endhighlight%}

for it to work.

Now: the server will pass on any arguments you send it in an http GET/POST to the script. But your script needs to receive them correctly. You can do this by writing:

{% highlight python %}

form = cgi.FieldStorage()
departure_date = form.getvalue('departure_date')

{% endhighlight %}

Now, in my browser, if I were add an argument at the end of the URL like this: "http://www.mysite.com/cgi-bin/nameofscript.py?departure_date=01/01/2001", my script will pick up the argument "departure_date" and set it to "01/01/2001".

That's it for the script side. Now for configuring the server!
Amazon have spent heaps of time making tutorials on [how to set up an instance]. I just followed that to create an ubuntu server. I'm sure the procedure is very similar in other distributions.
Make sure you can ssh in to the instance you created. I chose to set 'delete on termination' to false, although that's up to you.
I use [CyberDuck] for my FTP needs.

Because I screwed up so many times, I'm not too sure about the order in which these things need to be done. Maybe it doesn't really matter. Here's a shot at a step-by-step procedure:

1/ Install [lighttpd]. If using ubuntu, (sudo) apt-get install lighttpd

2/ Then, using your FTP client, (or git!) transfer your site across. Note where you put it. I'm not sure it really matters, but it seems customary to put it in /var/www. For some reason, your scripts need to be in the cgi-bin/ folder inside your website. e.g. like this: /var/www/mysite/cgi-bin/mypythonscript.py. Otherwise, the scripts won't work. This means that apart from your script(s), you may want an index.html at the website's root to welcome users...

3/ Enable cgi: (sudo) lighttpd-enable-mod cgi

4/ Open the configuration file using the text editor of your choice: (sudo) nano /etc/lighttpd/lighttpd.conf. Set the "server.document-root" to the root of your website (/var/www/mysite, if you follow the usual custom). It's important to make a note of the "server.username" and "server.groupname" values. You'll want your website to be owned by that user/group. Use chown and chgrp as necessary once you've uploaded the site. You'll also want to set the permissions of your site to 755 using chmod. A note of caution here: several how-to blogs seem to describe a slightly different procedure. I'm guessing they were for a different version of lighttpd. For instance, I came across instructions to manually add the cgi module within the config file (instead of what we did in 3/). This crashed my version.

5/ Open the mod config file: (sudo) nano /etc/lighttpd/conf-enabled/10-cgi.conf. Change: 

cgi.assign = ( "" => "" ) to cgi.assign = ( ".py" => "/usr/bin/python3" )

oon the right-hand-side, insert the path to your interpreter of choice. This is the step where we tell the server to run python3 if it encounters a .py file.

6/ Restart by calling (sudo) /etc/init.d/lighttpd restart.

A final note to those of us working in languages other than English: be very careful with character encodings. I had a stray accent inside a print() message, which resulted in an error-less blank web page. It took me ages to find what was going wrong.




[post]: /projects/2016/04/29/Finances-Publiques.html
[common gateway interface (CGI)]: https://en.wikipedia.org/wiki/Common_Gateway_Interface
[here]: https://docs.python.org/2/library/cgi.html
[how to set up an instance]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html
[CyberDuck]: https://cyberduck.io
[lighttpd]: https://www.lighttpd.net

