---
layout: post
title:  "Controlling spectroscopy experiments from a browser using signalR"
date:   2016-04-15 15:00:00 +0100
categories: Projects
---

My day job involves doing a lot of spectroscopy on molecules. In short, we build experiments that we control using a computer (see [a previous post on experimental control for photos]. In many cases, it's quite practical to be able to view incoming data while actually working on the experiment. A classic example is aligning the laser beam path to maximize for signal: unless the computer screen is facing you while you move mirrors, you quickly discover that you have to resort to weird yoga positions to get the job done. I'm no good at yoga, so I tried to come up with an alternative: use [NI's C# API (called DAQmx)] to do the hardware control, then use [SignalR] to push the data to a browser where it gets plotted using [plotly]. I'm hoping that once set up, I'd just need to place a tablet (or my mobile phone) on the optical table to view the data. Note: yes, you could remote desktop, VNC etc. And yes, it may be initially simpler get things up and running using LabView. But once the data can be pushed across the web, I can imagine doing other things with it (remote analysis and storage of data, for instance). And it seemed like a fun thing to try. So anyway, I got writing.

The hardware side is a textbook example of using NI's DAQmx. For this particular experiment, all we needed was to read 4 input channels N times at a fixed sample rate, initiated by an external TTL trigger pulse. Examples of very similar things come with the drivers when you install them on your computer. You create an instance of the Task object, to which you add analog input channels, configure triggers and timing. I put all that in the [DAQmxTriggeredMultiAIHardware.cs] class.

Now, for the signalR part. I basically worked through [this tutorial] where you create a fake stock ticker and adapted it to my needs. Skipping the details on how to set this up, the basic idea is that signalR lets us call C# methods from javascript and vice-versa. So on the C# side, we have a hub class (that I called PlotHub), which contains the methods that a user can call from the browser: start, stop, clearAll and save. 

{% highlight C# %}

public class PlotHub : Hub
	{
        private readonly Experiment _experiment;

        public PlotHub() : this(Experiment.Instance) { }

        public PlotHub(Experiment e)
        {
           _experiment = e;
        }

        public void Start(string parameters)
	{
            Experiment.Instance.StartExperiment(parameters);
	}
		.
		.
		.
	}

{% endhighlight %}

As you can see, these are just going to call methods in the hardware control class (called Experiment). Now on the webpage side, I make a button that calls the above function when pressed. I also collect some experimental parameters and sends them over:

{% highlight javascript %}

$('#startbutton').click(function() {
    var params = {
        'NumberOfPoints': document.querySelector('#NumberOfPoints').value,
        'AINames': fixedParams.AINames,
        'AIAddresses': fixedParams.AIAddresses,
        'AutoStart': document.querySelector('#AutoStart').value,
        'TriggerAddress': fixedParams.TriggerAddress,
        'SampleRate': document.querySelector('#SampleRate').value,
        'eosStop': document.querySelector('#eosstopcheckbox').checked,
        'eosSave': document.querySelector('#eosautosavecheckbox').checked,
        'savePath': document.querySelector('#savepathtextbox').value
    };
    // Call the Start method on the hub.
    pHub.server.start(JSON.stringify(params));
});

{% endhighlight %}

Once the data is collected, we need to push the data to the browser. This is done by doing the reverse: have a function on the webpage that can be called from the C# side:

{% highlight javascript %}
// Create a function that the hub can call to plot the data.
pHub.client.pushData = function (data) {
        .
        .
        .
    appendData(document.getElementById("plot"), jData);
        .
        .
        .
};

{% endhighlight %}

As you can see, this calls a function called 'appendData' that does the plotting.
On the experiment side, the Experiment class has a run loop in which the data gets pushed as it gets recorded by the NI card:

{% highlight C#%}

    .
    .
    .
while (es.Equals(ExperimentState.IsRunning))
{
    dataSet = hardware.Run();
    //Push data down to the client like this.
    Clients.All.pushData(dataSet.ToJson());
    .
    .
    .
            
} 
    .
    .
    .
{% endhighlight %}

There we go. Everything we need to control an experiment from a browser. The code can be found [here].

[a previous post on experimental control for photos]: /projects/2016/02/26/iChopin.html
[NI's C# API (called DAQmx)]: https://www.ni.com/dataacquisition/nidaqmx.htm
[SignalR]: http://www.asp.net/signalr
[plotly]: https://plot.ly/javascript/
[DAQmxTriggeredMultiAIHardware.cs]: https://github.com/Stok/EDMPlotter/blob/master/DAQ/DAQmxTriggeredMultiAIHardware.cs
[this tutorial]: http://www.asp.net/signalr/overview/getting-started/tutorial-server-broadcast-with-signalr
[here]: https://github.com/Stok/SRExpCtrl

