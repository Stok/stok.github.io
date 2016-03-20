var dataSet = loadDataset();
var currentEntry = selectNewEntry(dataSet);

function checkIfTrue() {
    return currentEntry.IsTrue;
}

function getSentence() {
    return currentEntry.sentence;
}

function selectNewEntry() {
        var length = dataSet.length;
        var randomIndex = Math.round(Math.random() * length);
        currentEntry = dataSet[randomIndex];
}

function loadDataset() {
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
        return json;
    };
    