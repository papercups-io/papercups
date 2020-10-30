### Friday, 30 October

- We released v1 of our **Reporting Dashboard** 📈 🚀 📊  [0]
- [Beta] Adding support for another variant of the **chat icon** [1]
  - _See it live on our [website](http://papercups.io/)!_
- Added docs for **getting started with Storytime** [2]
  - _Storytime allows you to view your users' screen live while chatting with them_
- Added a link to **view the live user session** from the Conversation UI [3]
- We now **archive stale conversations** that have been closed for over 14 days
  - Thanks for the help @daskycodes! 🎉 

_[0] Reporting Dashboard:_
> <img width="800" alt="Reporting Dashboard" src="https://user-images.githubusercontent.com/5264279/97723684-70894300-1aa2-11eb-90ae-60a49685a4c8.png">

_[1] New chat icon variant:_
> <img width="400" alt="Chat icon" src="https://user-images.githubusercontent.com/5264279/97723887-a62e2c00-1aa2-11eb-9c63-ee7282120397.png">

_[2] Setting up Storytime:_
> <img width="800" alt="Setting up Storytime" src="https://user-images.githubusercontent.com/5264279/97306773-4f6fea80-1835-11eb-9d80-2cbcfc8881a5.png">

_[3] View live session:_
> <img width="800" alt="View live session" src="https://user-images.githubusercontent.com/5264279/97623079-898ae900-19fb-11eb-8f07-ae5d0fc03e5f.png">

### Monday, 26 October

- Our new screen-sharing product — **Storytime** — is now in beta! 🚀 🔥 🎉 [0]
  - _Repo: https://github.com/papercups-io/storytime_
  - _Website: http://storytime.papercups.io/_
- You can now **hide the widget toggle button** and **open it programmatically** [1]

_[0] Storytime:_
> <img width="800" alt="Storytime" src="https://user-images.githubusercontent.com/5264279/96898977-56c27d00-145e-11eb-907b-ca8db13a0fa0.gif">

_[1] Hidden chat widget:_
> <img width="800" alt="Hidden chat widget" src="https://user-images.githubusercontent.com/5264279/97244402-04bb8780-17cf-11eb-9a30-08333a1d71ea.gif">

### Monday, 19 October

- Fixed issues with running app in Docker
- Added an API endpoint to **export customer data in CSV format**
- Added ability to **delete closed conversations**
- Improved tests, fixed some bugs, and added better type checking 🎉 

### Friday, 9 October

- We released our **FAQ chatbot** demo 🤖 [0]
  - Check it out! https://app.papercups.io/bot/demo
- Added ability to **set working hours** [1]
- **Customer details** are shown in the Conversations UI by default [2]
- You can now add **tags** to your customers and conversations [3]
- Released **v1.1.0** of our [chat widget](https://github.com/papercups-io/chat-widget)
- Added an **Easter Egg** to our chat 🔥
  - Try going to our [demo page](https://app.papercups.io/demo) and asking **"What is 2^11?"** in the chat window! 🤓

_[0] FAQ chatbot:_

> <img width="800" alt="FAQ Chatbot" src="https://user-images.githubusercontent.com/4218509/94747421-b6cc7480-0333-11eb-9a8f-807eb794b0a0.png">

_[1] Working hours:_

> <img width="800" alt="Working hours" src="https://user-images.githubusercontent.com/5264279/94756971-00828280-0367-11eb-8917-133591800fdc.png">

_[2] Customer details:_

> <img width="800" alt="Customer details" src="https://user-images.githubusercontent.com/5264279/95757987-d89ff280-0c75-11eb-85c2-72d6c8127f39.png">

_[3] Customer tags:_

> <img width="800" alt="Customer tags" src="https://user-images.githubusercontent.com/5264279/95757986-d89ff280-0c75-11eb-8d6d-55932e62c30e.png">

### Friday, 25 September

- Admin users can now **disable members** of their team [0]
- Removed console logs from production
- Added **`debug` mode** for better development experience [1]
  - Can be enabled by adding `?debug=1` to the query string, or setting the `REACT_APP_DEBUG_MODE_ENABLED` environment variable to `1` (`true`)
- We now display more customer info at the top of each conversation window [2]
- [Beta] Added support for **programmatically opening/closing** chat widget [3]
  - Available in `"@papercups-io/chat-widget": "^1.1.0-beta.3"`

_[0] Admin disabling user:_
| Admin view | User view |
|---|---|
| <img alt="Admin view" src="https://user-images.githubusercontent.com/5264279/93922581-1f867200-fce0-11ea-91ec-0f5548ade0de.png"> | <img alt="User view" src="https://user-images.githubusercontent.com/5264279/93922583-1f867200-fce0-11ea-801a-4cb516e07879.png"> |

_[1] Debug mode:_

> <img width="800" alt="Debug mode" src="https://user-images.githubusercontent.com/5264279/94451891-f0a74a80-017c-11eb-89d1-c453c744e0af.gif">

_[2] More customer details:_

> <img width="800" alt="More customer details" src="https://user-images.githubusercontent.com/5264279/94452523-a1154e80-017d-11eb-9756-a68be8fbbc4d.png">

_[3] Programmatically toggle chat widget (beta):_

> <img width="800" alt="Toggle chat widget" src="https://user-images.githubusercontent.com/5264279/94452042-1cc2cb80-017d-11eb-9550-d0b92a12b2b0.gif">

### Friday, 18 September

- Added **"admin" and "user" roles** to start restricting access to certain functionality [0]
- Added support for storing **ad hoc metadata** on a customer [1]
- Added **support for callbacks** in chat widget [2]
- Display company name instead of "Bot" in chat widget
- Added initial **API docs** (work-in-progress): https://github.com/papercups-io/papercups/wiki/API-Docs
- Fix Slack messages not triggering webhook events 🐞

_[0] Admin vs User roles:_

> <img width="800" alt="Admin role" src="https://user-images.githubusercontent.com/5264279/93624035-acae8b80-f9ad-11ea-9549-9e21eb247177.png
> ">

_[1] Ad hoc customer metadata in chat widget config:_

```javascript
<script>
  window.Papercups = {
    config: {
      // ...
      customer: {
        name: 'Test User',
        email: 'test@test.com',
        external_id: '123',
        // Add whatever extra info you like here
        metadata: {
          plan: 'starter',
          registered_at: '2020-09-01',
          age: 25,
          valid: true,
        },
      },
    },
  };
</script>
```

_[2] New chat widget callbacks:_

```javascript
  onChatOpened?: () => void;
  onChatClosed?: () => void;
  onMessageSent?: (message: Message) => void;
  onMessageReceived?: (message: Message) => void;
```

### Thursday, 10 September

- [[Beta]](https://github.com/papercups-io/papercups/pull/216) Your customers with valid email addresses will now be **notified via email** in case they miss a message from you 🎉
- Users can now **reset their passwords** [0]

_[0] Reset password:_
| Step 1 | Step 2 | Step 3 |
|---|---|---|
| <img alt="Reset password 1" src="https://user-images.githubusercontent.com/5264279/92841795-c437b400-f3b0-11ea-8489-fd5f7a89eed2.png"> | <img alt="Reset password 2" src="https://user-images.githubusercontent.com/5264279/92841796-c4d04a80-f3b0-11ea-9e39-6c211ab4f49c.png"> | <img alt="Reset password 3" src="https://user-images.githubusercontent.com/5264279/92841961-f34e2580-f3b0-11ea-9086-fbc86a2a596f.png"> |

### Monday, 7 September

- Added the ability to display your **online status** in the chat widget [0]
- Display more **metadata** in the Customers UI [1]

_[0] Online/offline status in chat widget:_

> <img width="400" alt="Online status" src="https://user-images.githubusercontent.com/5264279/92402851-506e8080-f0fe-11ea-90c8-730a37c001e3.png">

_[1] Customer metadata:_

> <img width="800" alt="Customer metadata" src="https://user-images.githubusercontent.com/5264279/92283529-128b1580-eece-11ea-8203-cf2d101554a9.gif">

### Friday, 28 August

- Added a new **Customers UI** to the dashboard [0]
- Added an alert to the Integrations page about a **known Slack issue** [1]

_[0] Customers UI (beta):_

> <img width="800" alt="Customers UI" src="https://user-images.githubusercontent.com/5264279/91613987-a1d47e00-e94e-11ea-99c4-72eb0688db88.png">

_[1] Slack integration alert:_

> <img width="800" alt="Slack integration alert" src="https://user-images.githubusercontent.com/5264279/91459293-7705ff00-e854-11ea-967f-836de45f9846.png">

### Tuesday, 25 August

- Added support for **webhook integrations** [0]
  - Docs: https://github.com/papercups-io/papercups/wiki/Event-Subscriptions-with-Webhooks
- Added more customer metadata to the dashboard [1]
- Added **more customer metadata to Slack messages** [2]
- Added ability to **disable registration** without invitation for self-hosted instances
- Minor security improvements to the chat widget

_[0] Setting up a webhook:_

> <img width="800" alt="Add webhook url" src="https://user-images.githubusercontent.com/5264279/90997390-63764200-e58f-11ea-81ed-e2892aab55c5.png">

_[1] Customer metadata in dashboard:_

> <img width="600" alt="Dashboard" src="https://user-images.githubusercontent.com/5264279/91189662-b8fe3c00-e6c0-11ea-8580-37e889d1d1bf.png">

_[2] Customer metadata in Slack:_

> <img width="600" alt="Slack" src="https://user-images.githubusercontent.com/5264279/91188044-d92cfb80-e6be-11ea-9dab-7a6763c199c5.png">

### Thursday, 20 August

- Added **support for React Native**: https://github.com/papercups-io/chat-widget-native [0]

_[0] React Native support:_

> <img width="400" alt="React Native" src="https://user-images.githubusercontent.com/5264279/90348303-6c04d080-e003-11ea-8976-6f9d355ca4c8.png">
