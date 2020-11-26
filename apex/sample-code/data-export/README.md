# APEX_DATA_EXPORT API Examples
The APEX_DATA_EXPORT API was added to Oracle APEX 20.2 and allows you to export the results of any query context in several output formats.

These code snippets were used during the APEX Office Hours session about [Super Easy Report Printing in Oracle APEX 20.2!](https://asktom.oracle.com/pls/apex/asktom.search?oh=10265)

## Prerequisites
- Requires Oracle APEX 20.2
- Requires at least one application
- Requires the installation of the EMP / DEPT Sample Dataset

Please go to SQL Workshop / Utilities / Sample Datasets. Click the Install button for EMP / DEPT.

## Examples
- [1-basic.sql](1-basic.sql)
- [2-columns.sql](2-columns.sql)
- [3-column-groups.sql](3-column-groups.sql)
- [4-highlights.sql](4-highlights.sql)
- [5-aggregates.sql](5-aggregates.sql)
- [6-styling.sql](6-styling.sql)
- [7-mail.sql](7-mail.sql)

## How to use the examples
Each example can be run as a REST Resource Handler.

- Go to SQL Workshop / RESTful Services
- Register your schema for ORDS
- Create a new module
    - Name: **export**
- Add a Resource Template for each example
    - Add a Resource Handler
        - Method: **GET** (use **POST** for example `7-mail`)
        - Source Type: PL/SQL

The examples require an APEX session. Make sure that at least one application is created in your workspace. In each example you'll find the following snippet:

```sql
    apex_session.create_session(
        p_app_id    => 101,
        p_page_id   => 1,
        p_username  => 'DUMMY' );
```

Make sure to change the `p_app_id` and `p_page_id` into valid values.

## About `7-mail` POST request
The last example shows how to send an export trough email. This example requires more configuration.

- Configure an email server in your APEX Instance
- Configure the email template below
- Use a REST client to make the `POST` request

### Email template
- Template Name: **EMPLOYEES**
- Static Identifier: **EMPLOYEES**
- Email Subject: **Employee overview**
- HTML Header:
```html
<!doctype html>
<html>
<head>
<meta charset="UTF-8">
<title>Hello #NAME#,</title>
<link href='http://fonts.googleapis.com/css?family=Open+Sans:400,300' rel='stylesheet' type='text/css'>
<style>
    *{
        box-sizing: border-box;
        -moz-box-sizing: border-box;
    }
    html,body{
        background: #eeeeee;
        font-family: 'Open Sans', sans-serif, Helvetica, Arial;
    }
    img{
        max-width: 100%;
    }
    /* This is what it makes reponsive. Double check before you use it! */
    @media only screen and (max-width: 480px){
        table tr td{
            width: 100% !important;
            float: left;
        }
    }
</style>
</head>
```
- HTML Body:
```html
<body style="background: #eeeeee; padding: 10px; font-family: 'Open Sans', sans-serif, Helvetica, Arial;">
<center>
<table width="100%" cellpadding="0" cellspacing="0" bgcolor="FFFFFF" style="background: #ffffff; max-width: 600px !important; margin: 0 auto; background: #ffffff;">
    <tr>
        <td style="padding: 20px; text-align: center; background: #BC513E;">
            <h1 style="color: #ffffff">Hi #NAME#,</h1>
        </td>
    </tr>
    <tr>
        <td style="padding: 20px; text-align: center;">
            <p style="font-size:30px; margin: 5px;">Employee overview</p>
            <p>Please see the latest employee details in the attached document.</p>
        </td>
    </tr>
    <tr>
        <td>
            <img src="https://apex.oracle.com/assets/media/images/homepage/apex-mountain-bg.jpg?v=1" />
        </td>
    </tr>
    <tr>
        <td style="padding: 20px;">
            <table border="0" cellpadding="0">
                <tr>
                    <td width="30%" style="width: 30%; padding: 10px;">
                        <img src="https://apex.oracle.com/assets/media/images/screenshots/whats-new-202/report-printing.png?v=1" />
                    </td>
                    <td width="70%" style="width: 70%; padding: 10px; text-align: left;">
                        <h3>Report Printing</h3>
                        <p>Report Printing in Oracle APEX 20.2 offers lots of options and possibilities.</p>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
    <tr>
        <td style="padding: 20px; background: #2B2E34;">
            <table border="0" cellpadding="0" cellspacing="0" a>
                <tr>
                    <td width="50%" style="width: 50%; padding: 10px; color: #ffffff; text-align: left;" valign="top">
                        <img src="https://apex.oracle.com/assets/media/company-logos/oracle-white.png?v=1"></img>
                    </td>
                    <td width="50%" style="width: 50%; padding: 10px; color: #ffffff; text-align: left;" valign="top">
                        <h2>Happy APEXing!</h2>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
<p style="text-align: center; color: #666666; font-size: 12px; margin: 10px 0;">
    Copyright © 2020. All&nbsp;rights&nbsp;reserved.<br />
</p>
</center>
</body>
```
- HTML Footer
```html
</html>
```
- Plain Text Format:
```txt
Hi #NAME#,
Please see the latest employee overview as attached document.
```

### Request settings for REST Client
- Method: **POST**
- Body: **Multipart Form**

Add three Form items:
- format: **xlsx**
- name: **`<Your name>`**
- to: **`<your emailaddress>`**

### Example using Curl
```
curl -v -F format=xlsx -F name="John Doe" -F to=example@oracle.com <REST_HANDLER_URL>
