var dataSet = LoadDataset();
var currentEntry = SelectNewEntry(dataSet);

function CheckIfTrue() {
    return currentEntry.IsTrue;
}

function GetSentence() {
    return currentEntry.sentence;
}

function SelectNewEntry() {
        var length = dataSet.length;
        var randomIndex = Math.round(Math.random() * length);
        currentEntry = dataSet[randomIndex];
}

function LoadDataset() {
        var json = null;
        $.ajax({
            'async': false,
            'global': false,
            'url': "/ccQuiz/allLaws.json",//"https://github.com/Stok/CCGenerator/blob/master/allLaws.json",
            'dataType': "json",
            'success': function (data) {
                json = data;
            }
        });
        //var length = json.length;
        //var randomIndex = Math.round(Math.random() * length);
        //alert(json[randomIndex].sentence)
        //return json[randomIndex];
        return json;
    };
    