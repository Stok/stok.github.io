---
layout: post
title:  "Scraping data from the finances publiques"
date:   2016-04-29 00:26:57 +0100
categories: Projects
---

The admin staff in our lab have a lot of very tedious procedures they need to follow. For many of these, I don't see the point of doing them at all, let alone understand why they aren't done by a computer. Anyhow, as a gesture of good will, and in the hope that they'll send less paperwork my way, I wrote a script to help them out. It automates part of the procedure for processing travel authorizations.

Before any of 'us' (the academic staff) attend a conference / go work in some other lab / go give a seminar somewhere, we have to fill out a 'demande d'ordre de mission', a form requesting to work off campus. We notify them of where we're going, the departure and return dates, any registration, travel and hotel costs, and, weirdly, how many times I'm going to eat (more on that later).

I only recently found out what they did with this information. A key step in their work is estimating the cost of the trip. Unlike in other institutions I worked at, the cost of the trip isn't calculated based on receipts I bring back. Those are only used to verify that I actually went, instead of siphoning research funds to buy myself a new TV. Instead, the estimate is entirely based on a French government website.

Amazingly, the government tabulated a daily allowance for each possible destination country. This is an estimate of how much they think it costs for someone to be in that place for 24 hours (henceforth referred to as "le barême"). In principle, this is the daily allowance whose sum they disburse. Our staff look up this barême for the dates of the trip, paying particular attention to any mid-trip changes. 

But even more amazingly, these daily estimates are given in the local currency of the destination. So our staff then look up a different part of the same government website to get the official exchange rate for the proposed travel dates, and convert the allowance back into euros. 

So they basically tediously evaluate

<script type="text/x-mathjax-config">
        MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});
</script>
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_CHTML">
</script>

$c = \sum\limits_{days = i}^{n}e_i B_{i}$


by hand ($c$ is the amount to disburse, $e_i$ is the exchange rate and $B_i$ is the barême). This should be automated! That's where I come in. I decided to script in python (3.5.1), and made use of [requests] and [beautiful soup] libraries. I also used the [datetime] module.

{% highlight python%}

import requests
from bs4 import BeautifulSoup
from datetime import datetime as dt
from datetime import timedelta

{% endhighlight %}

I need to:

1/ Get a list of country/region codes. Once. Print it out, and stick it on their office wall. (I'm assuming they don't change very much.) Using requests and beautiful soup, the function looks like this:

{% highlight python%}

def getCountryCodes(url):
        
        r = requests.get(url)
        print(r.status_code, r.reason)
        #Sometimes, I got weird BOM (byte order marks) when parsing, so added this.
        content = r.text.encode('ascii', 'ignore')

        soup = BeautifulSoup(content, 'html.parser')
        #I got away with searching directly for options, because there were no other select tags on the page.
        countriesRaw = soup.find_all('option')

        allCountries = []
        for c in countriesRaw :
                allCountries.append((c.getText(), c.get('value')))
        
        return allCountries

{% endhighlight %}

If "http://www.economie.gouv.fr/dgfip/mission_taux_chancellerie/frais" is passed as argument, the code produces this result:

[('Liste des pays :', '0'), ('AFGHANISTAN', 'AF'), ('AFRIQUE DU SUD', 'ZA'), ('ALBANIE', 'AL'), [...] ('UNION ECONOMIQUE ET MONETAIRE', 'EU'), ('URUGUAY', 'UY'), ('VANUATU', 'VU'), ('VENEZUELA', 'VE'), ('VIETNAM', 'VN'), ('WALLIS ET FUTUNA, ILES', 'WF'), ('YEMEN (REPUBLIQUE DU)', 'YE'), ('YOUGOSLAVIE (VOIR SERBIE-MONTENEGRO)', 'YU'), ('ZAMBIE', 'ZM'), ('ZIMBABWE', 'ZW')]

I guess some government employees are far more adventurous than I am...

2/ For a country of choice, look up the dates when parameters got modified. This is to be done for both the barême and the exchange rate. These modification dates appear as options in a select tag, so I can just parse them using beautiful soup. Here is the function used:

{% highlight python%}

def getChangeDates(url, countryCode) :
        #This part gets the dates that the rate got changed
        r = requests.get(url + countryCode)
        print(r.status_code, r.reason)
        content = r.text.encode('ascii', 'ignore')

        soup = BeautifulSoup(content, 'html.parser')

        changeDatesRaw = soup.find(id='edit-date').find_all('option')
        changeDates = []
        for date in changeDatesRaw :
                changeDates.append(date.get('value'))

        return changeDates

{% endhighlight %}
Note the url needed is different for this function. See full code [here].

3/ Given my departure and return dates, work out which rates are to be used and query them. Their site makes this a little awkward. The values I want to parse appear in a read-only input text box that updates its value when the user selects a date. So to get the value for a specific date, I need to do an HTTP POST with the right payload (the date of interest), to which their server returns the entire page with updated values. Here's the function that does the querying.

{% highlight python%}

def getValueAtDate(url, countryCode, date, valueID):
        #This part gets the value for a particular date
        payload = {
                'date' : date.strftime("%Y-%m-%d %H:%M:%S")
        }
        r = requests.post(url + countryCode, payload)
        print(r.status_code, r.reason)
        content = r.text.encode('ascii', 'ignore')

        soup = BeautifulSoup(content, 'html.parser')
        value = float(soup.find(id=valueID).get('value').replace(",", "."))

        return value

{% endhighlight %}

4/ Evaluate $c$, the weighted sum.

And we're all done! Or, not. The government stipulates rules on how the 'bareme' is to be spent: No more than 65% of it is to be spent on lodging, and the rest must be divided into costs for two meals (17.5% each), to be taken at specific times (wait for it) of their choosing. If I leave my house in the morning, then stay overnight, I will receive 100% of that day's 'bareme'. But if I leave in the afternoon/evening, I only get 82.5% / 65% of it. Similar rules apply for the return date. If this seems sensible to you, keep reading. Anyway, the upshot is that the departure/arrival dates get weighted by an extra coefficient, which I'll just add in as weights.

5/ Add these new weights in the sum:

$c = \sum\limits_{days = i}^{n}w_i e_i B_{i}$

Now. OK. Bear with me, we're still not done. As it turns out, everyone knows these estimates are far too high. For most countries, I could receive far more than I ever paid. So they need to find a way to reduce the amounts to disburse without it appearing in the official figures. Apparently, saying "I only need reimbursement for 2 days" isn't acceptable. The rules state that if I am gone for 3 days, a hotel room for each night (and the associated proof of payment) is mandatory. But! Fasting is acceptable. I can just say: I didn't eat that day. So here's the final addition to this sad project:

6/ After the trip, based on actual expenditure, calculate how many '17.5% of bareme'-meals I ate (I'm going to call this $N_m$). Using this, estimate the final cost of the trip assuming, for instance, that I didn't eat during the second half of my trip. 

The full script can be found [here].

I still can't get my head around the fact that they meticulously impose meal times for their initial estimates (making it more complicated to compute than is necessary), then accept an obvious fudging of numbers at the end to correct for their inflated 'bareme' (making it more complicated again!). All this instead of adding up the receipts to begin with. 
I did suggest they simplify their calculation to: 

$c =  \left(0.175 * N_m + 0.65 * N_{days} \right) * B * e$

 but I was told that it would "give a meaningless answer if the barême changed mid-trip", as if their current procedure gave a meaningful one.

I wonder if they ever compile statistics based on all the data they have. It seems interesting that the French government isn't the least bit concerned that their employees appear to systematically starve themselves while abroad. Maybe they just interpret it as evidence of how bad the food is.

Anyway, I'm glad this project is over. It was driving me slightly crazy. I put the script on an AWS micro-instance running lighttpd, which you can query from here. More on how I did that in a separate post. Here is the result: Insert the departure/return dates, the destination country code and the 'meal cap' and click send to obtain an estimate of the reimbursement. 

<div>
	<form action="http://ec2-34-248-121-79.eu-west-1.compute.amazonaws.com/cgi-bin/scrapefp.py" method='get' id='info_trip'>
        <li> 
            <label for='departure_date'>Departure Date</label>
            <input type='text' id='departure_date' name='departure_date' value='dd/mm/yy_HH:MM'/>
        </li>
        <li>
            <label for='return_date'>Return Date</label>
            <input id='return_date' name='return_date' value='dd/mm/yy_HH:MM'/>
        </li>
        <li>
            <label for='country_code'>Country Code</label>
            <input type='text' id='country_code' name='country_code' value='GB'/>
        </li>
        <li>
            <label for='meal_cap'>Max. Number of meals to reimburse</label>
            <input type='text' id='meal_cap' name='meal_cap' value='10000'>
        </li>
        <input type='submit' value="Send">
	</form>
    
	
</div>


[requests]: http://docs.python-requests.org/en/master/#
[beautiful soup]: https://www.crummy.com/software/BeautifulSoup/bs4/doc/
[datetime]: https://docs.python.org/2/library/datetime.html
[here]: https://github.com/Stok/scrapefp/blob/master/cgi-bin/scrapefp.py

