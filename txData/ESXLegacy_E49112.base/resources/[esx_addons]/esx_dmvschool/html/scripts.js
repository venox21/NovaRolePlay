/*
 * DMV Fahrschule Los Santos - Scripts (Theorieprüfung)
 * UTF-8 Encoding
 */

var questionNumber = 1;
var userAnswer = [];
var goodAnswer = [];
var questionUsed = [];
var nbQuestionToAnswer = 10;
var nbAnswerNeeded = 5;
var nbPossibleQuestions = 10;
var lastClick = 0;

function getRandomQuestion() {
	var random = Math.floor(Math.random() * nbPossibleQuestions);
	while (true) {
		if (questionUsed.indexOf(random) === -1) {
			break;
		}
		random = Math.floor(Math.random() * nbPossibleQuestions);
	}
	questionUsed.push(random);
	return random;
}

function closeMain() {
	$(".home").css("display", "none");
}

function openMain() {
	$(".home").css("display", "block");
}

function closeAll() {
	$(".body").css("display", "none");
}

function updateProgress() {
	var pct = Math.round(((questionNumber - 1) / nbQuestionToAnswer) * 100);
	$("#progress-fill").css("width", pct + "%");
	$("#progress-percent").text(pct + "% Abgeschlossen");
	$(".questionnaire-container .progression").val(questionNumber - 1);
}

function openQuestionnaire() {
	closeAll();
	$(".questionnaire-container").css("display", "block");
	var randomQuestion = getRandomQuestion();

	$("#questionNumero").text("Frage " + questionNumber + " von " + nbQuestionToAnswer);
	$("#question").text(tableauQuestion[randomQuestion].question);
	$(".answerA").text(tableauQuestion[randomQuestion].propositionA);
	$(".answerB").text(tableauQuestion[randomQuestion].propositionB);
	$(".answerC").text(tableauQuestion[randomQuestion].propositionC);
	$(".answerD").text(tableauQuestion[randomQuestion].propositionD);

	$('input[name=question]').prop('checked', false);
	$('.option-card').removeClass('selected');

	goodAnswer.push(tableauQuestion[randomQuestion].reponse);
	updateProgress();
}

function openResultGood() {
	closeAll();
	$("#progress-fill").css("width", "100%");
	$("#progress-percent").text("100% Bestanden");
	$(".resultGood").css("display", "block");
}

function openResultBad() {
	closeAll();
	$(".resultBad").css("display", "block");
}

function openContainer() {
	$(".question-container").fadeIn(200);
}

function closeContainer() {
	$(".question-container").fadeOut(150);
}

// Option Cards anklickbar machen
$(document).on('click', '.option-card', function() {
	$('.option-card').removeClass('selected');
	$(this).addClass('selected');
	$(this).find('input[type=radio]').prop('checked', true);
});

// NUI Messages empfangen
window.addEventListener('message', function (event) {
	var item = event.data;

	if (item.openQuestion === true) {
		userAnswer = [];
		goodAnswer = [];
		questionUsed = [];
		questionNumber = 1;
		openContainer();
		openMain();
	}

	if (item.openQuestion === false) {
		closeContainer();
		closeMain();
		closeAll();
	}

	if (item.openSection === "question") {
		closeAll();
		openQuestionnaire();
	}
});

// Buttons
$(".btnQuestion").click(function () {
	$.post(`https://${GetParentResourceName()}/question`, JSON.stringify({}));
});

$(".btnClose").click(function () {
	$.post(`https://${GetParentResourceName()}/close`, JSON.stringify({}));
	userAnswer = [];
	goodAnswer = [];
	questionUsed = [];
	questionNumber = 1;
});

$(".btnKick").click(function () {
	$.post(`https://${GetParentResourceName()}/kick`, JSON.stringify({}));
	userAnswer = [];
	goodAnswer = [];
	questionUsed = [];
	questionNumber = 1;
});

// Form Submit (Antwort bestätigen)
$("#question-form").submit(function (e) {
	e.preventDefault();

	var selected = $('input[name="question"]:checked').val();
	if (!selected) {
		// Visuelle Rückmeldung bei fehlender Auswahl
		$('.options-grid').css('animation', 'none');
		setTimeout(function() {
			$('.options-grid').css('animation', 'shake 0.3s ease');
		}, 10);
		return false;
	}

	userAnswer.push(selected);

	if (questionNumber < nbQuestionToAnswer) {
		questionNumber++;
		openQuestionnaire();
	} else {
		// Prüfung beendet: Auswertung
		var nbGoodAnswer = 0;
		for (var i = 0; i < nbQuestionToAnswer; i++) {
			if (userAnswer[i] === goodAnswer[i]) {
				nbGoodAnswer++;
			}
		}

		closeAll();
		if (nbGoodAnswer >= nbAnswerNeeded) {
			openResultGood();
		} else {
			openResultBad();
		}
	}

	return false;
});
