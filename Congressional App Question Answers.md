# ForkCast
## Please briefly describe what your app does?
The Forkcast app is an app that is made to help people achieve their macros and food goals while staying within their dietary restrictions, not having to search high and low for recipes that match for them, and still being able to go outside to eat. The user first inputs their food macro goals and dietary restrictions, and then they can choose between either searching for restaurants that could have items that match these goals or using a restaurant of their choice. After the restaurant is selected, menu items are presented to the user so that they can look over different food items and how much they match their goals, as well as see if there are items that would work with substitutions/modifications. The user can always save a restaurant or items to look back at later. Finally, the user can click a google maps link, website link, or doordash link to order their food.


## What inspired you to create this app?
I was inspired to create this app through an entrepreneurship camp I had done over the summer from Prep for Prep called IFE. In the camp, we had to create a business idea, and then create an app/website on it. The idea of the Forkcast app had come from there, as this was an idea that my friends and I had thought of, but ended up abandoning for a different idea that would work better instead. However, I thought that this app could still be helpful for people after my own reflection upon this idea and conversations with my family and friends on what they thought of this app idea, so I decided to make this app for the Congressional App Challenge. An app like this would help a lot of people achieve their macros and food goals while staying within dietary restrictions much more easily, which I would use in my personal life.


## What technical difficulties did you face programming your app?
One technical difficulty I faced while programming my app was figuring out how to get access to menu and restaurant data. When I searched up how to do this, most of the results I found were paid or made for large business companies. The resolution I came to is that we are in the era of AI! Gemini is powerful enough that it can do searches and connect to maps to find accurate results from restaurants, which is what I ended up connecting the app to.

Another difficulty I faced while making the app is figuring out how to store the user’s data while making it secure. To solve this issue, I decided to make my Flutter app act as a frontend to the backend, which is a website that I am hosting on Render. This worked for me as I knew how to code both Python and Flutter, so I combined the two and decided to store the data on MongoDB, as I had used that with Python before. That way, the data is secure, but the user can still use the app like normal.


## What would you change about your app if you were to create a 2.0 version? 
If I had to create a 2.0 version of my app, I would first send it to family/friends for them to test and take in improvement ideas. However, some ideas I have now for my 2.0 version are to add much more integrated functionality with Google Maps, such as viewing restaurants that match on a map. In addition, I would also do more research on how to get accurate food macro results of restaurants, and how to get an accurate menu. Finally, I would add the ability to search/scan a menu in person from an image, then find items that could match the user's macros.


## If you used AI, tell us how you used it and what your team contributed directly. Please list the AI tools you used and briefly explain how they helped. Then describe what your team designed, coded, changed, tested, or finalized yourselves.
I used AI as a tool to help debug and design my app and backend (website). I used Claude Code while coding in VSCode to help me figure out what was not working in my app or why I was receiving an error, as well as helping me plan out how to approach an organization task in the app (such as how I can ensure that the screens are split up correctly). I used Claude Design to design the look and feel of my app, as it helps to make the app feel and be consistent while looking good. After the design was made, I implemented most of the design into the Flutter app + website myself, but asked Claude Code to help me with the parts I did not understand.

I created the backend of the app, including the initial website, the email system, the MongoDB setup, etc. I also created the basic parts of the frontend of the app, but implementing the design of the app was mostly done by Claude.


## What did you learn or take away from participating in the Congressional App Challenge?
Some things that I learned from participating in the Congressional App Challenge is how to use AI (and Claude Design) efficiently while doing most of the coding yourself, and that it is always important to get others to test your app so you can receive feedback.
