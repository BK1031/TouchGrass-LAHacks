### Touch Grass is a fun and interactive mobile app that promotes fitness and the outdoors. With the app, friends can send "attacks" to force each other out of houses and buildings to touch grass.

## Inspiration
We were inspired by the board game Battleship as well as some mobile games like Pokemon Go.


## What it does

Touch Grass is an app that motivates people to leave their homes and quite literally touch grass. Users in a friend group send “attacks” by guessing their location similar to the popular board game, Battleship. The games point system also is centered around physical fitness and outdoor exploration. When a user is in the vicinity of an attack, they are notified and they have a limited amount of time to leave the affected area, or risk losing points. Overall, we hope that this game will encourage people to be more active and spend time outdoors through a fun and interactive medium.

## How we built it

The mobile app was built using Flutter, a cross-platform development framework that allows us to ship high-quality applications for both iOS and Android from the exact same codebase. This allowed us to speed through development while retaining the possibility to entertain a wide user base. The backend architecture was split between Firebase and a few custom services we wrote. We used Firebase for authentication, storage, and Firestore, its document database. This allowed us to iterate quickly and prototype new features without having to worry about building our own APIs. However, one downside of the serverless approach in this case is that it limited us in where our application logic could run. To solve this, we created a Python service that interacted with the Gemini API in order to utilize its capabilities in our app. We also wrote a Go service that was responsible for managing game logic in the cloud, almost acting like a game engine. This was a very interesting paradigm a
s Flutter and the backend services never directly interacted, but used Firebase as an intermediary.

## Challenges we ran into
We ran into issues with integration, as team members all had varying experience with flutter mobile development, however, each team member was able to learn something new and contribute to the evolution of the project. 

## Accomplishments that we're proud of
An accomplishment that we are proud of is that we followed through with our vision for this interactive app, and that we were able to integrate some machine learning algorithms learned in school and even use some of the latest LLM models through sponsor APIs. 

## What we learned
Most of our team was completely brand new to mobile development, so learning Flutter and just how to develop for mobile was a big challenge for us initially. We also created a pretty unique backend architecture around Firebase and our backend services. We learned a lot about deploying services that can work together from unusual places.

## What's next for Touch Grass
We plan on resolving any major issues with the app and deploying it among friends to see if it's fun and effective. We also plan to add new type of “attacks” and mechanics to the game to make it even more appealing and fun.
