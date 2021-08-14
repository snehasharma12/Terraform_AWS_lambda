const AWS = require('aws-sdk');
const querystring = require('querystring');

// Object to handle email
var ses = new AWS.SES();

exports.handler = function (event, context, callback) {
    const params = querystring.parse(event.body);
    
    var emailParams = {
        Destination: {
            ToAddresses: ["sharma.sn@northeastern.edu"]
        },
        Message: {
            Body: {
                Text: {
                    Data: "Name: " + params['name'] + 
                    "\nEMail: " + params['email'] +
                    "\nMessage: " + params['messages']
                }
            },
            Subject: {
                Data: "Message Received from " + params['name']
            }
        },
        Source: "sharma.sn@northeastern.edu"
    };
    
    ses.sendEmail(emailParams, function(err, data) {
        if (err) console.log(err, err.stack); // an error occurred
        else     console.log(data);           // successful response
    });
    
    const response = {
        statusCode: 200,
        headers: { 'Access-Control-Allow-Origin': 'http://snehasharma.tk' },
        body: JSON.stringify( 'Thank you, ' + params ['name'] + '! ' + 
                             'Your message is received by ' + params ['to'] + '! ' +
                             'She will contact you soon!! '),
    };
    callback(null, response);
};
