var express =       require("express");
var fs      =       require("fs");
var request =       require("request");

config = {
	slack: {
		client_id: process.env.SLACK_CLIENT_ID,
		client_secret: process.env.SLACK_CLIENT_SECRET
	}
}

/* MIDDLEWARES */
var app = express()
app.use(express.urlencoded({extended: true}));
app.use(express.json());
app.use(express.static('public'))
app.set('view engine', 'ejs');

function code2token(code, cb) {
	form = {client_id: config.slack.client_id, client_secret: config.slack.client_secret, code}
	request.post({
		url: 'https://slack.com/api/oauth.access',
		form: form
	}, function(err, res, body) {
		console.log(body)
		try {
			cb(JSON.parse(body).incoming_webhook.url);
		}
		catch(e) {
			cb("")
		}
	})
}

app.get('/slack', (req, res) => {
	code = req.query.code
	if (code == undefined) {
		res.redirect("/");
		return;
	}
	code2token(code, function(token) {
		console.log("here")
		res.render('webredirect', {token})
	})
})

app.get('/github/webhook', (req, res) => {
	res.end();
})

app.listen(process.env.PORT || 8089)
