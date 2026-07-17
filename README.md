# Problem statement

### _It's dinner time!_ Create an application that helps users find the most relevant recipes that they can prepare with the ingredients that they have at home

## Objective

Deliver a prototype web application to answer the above problem statement.

__✅ Must have's__

- A back-end with Ruby on Rails (If you don't know Ruby on Rails, refer to the FAQ)
- A PostgreSQL relational database
- A well-thought user experience

__🚫 Don'ts__

- Excessive effort in styling
- Features which don't directly answer the above statement
- Over-engineer your prototype

## Deliverable

- The codebase should be pushed on the current GitHub private repository.
- 2 or 3 user stories that address the statement in your repo's `README.md`.
- The application accessible online (a personal server, fly.io or something else). If you can't deploy your app online, refer to the FAQ)
- Submission of the above via [this form](https://forms.gle/siH7Rezuq2V1mUJGA).
- If you're on Mac, make sure your browser has [permission to share the screen](https://support.apple.com/en-al/guide/mac-help/mchld6aa7d23/mac).


## Data

Please start from the following dataset to perform the assignment:
[english-language recipes](https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz) scraped from www.allrecipes.com with [recipe-scrapers](https://github.com/hhursev/recipe-scrapers)

Download it with this command if the above link doesn't work:
```sh textWrap
wget https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz && gzip -dc recipes-en.json.gz > recipes-en.json
```

## FAQ

<details>
<summary><i>I'm a back-end developer or don't know React, what do I do?</i></summary>

Just make the simplest UI, style isn't important and server rendered HTML pages will do!
</details>

<details>
<summary><i>Can I have a time extension for the test?</i></summary>

No worries, we know that unforeseen events happen, simply reach out to the recruiter you've been
talking with to discuss this.
</details>

<details>
<summary><i>Can I transform the dataset before seeding it in the DB</i></summary>

Absolutely, feel free to post-process the dataset as needed to fit your needs.
</details>

<details>
<summary><i>Should I rather implement option X or option Y</i></summary>

That decision is up to you and part of the challenge. Please document your choice
to be able to explain your reflexion and choice to your interviewer for the
challenge debrief.
</details>

<details>
<summary><i>Do I really have to deploy the application online?</i></summary>
Deploying the application does ensure a smooth interview experience by allowing interviewers to test your code live. However, you should not overinvest time (or money) on this if you really can't figure it. You can alternatively provide demo videos as a worst case option, as interviewers won't checkout and run the application to cover for missing demo or online version. In case you don't have an online application, please make sure everything is working smoothly
locally before your debrief interview.
  
</details>

<details>
<summary><i>I don't know <b>Ruby on Rails</b></i></summary>

That probably means you're applying for a managerial position, so it's fine to
pick another language of your choice to perform this task.
</details>

<details>


<summary><i>Can I use AI tools?</b></i></summary>

You are free to use AI tools to assist you in completing this case study. To maintain transparency, please document which AI tools you used during the assignment.

For each tool, briefly explain:
- The main tasks or problems for which you used it.
- How you validated and refined any AI-generated code.

Note: While AI can be a valuable assistant, interviewers will assess your ability to understand the entire codebase, explain key technical choices, and effectively answer technical questions about improvements. We expect candidates to use AI as a supportive tool rather than having it generate the complete solution. AI should supplement your coding process, not replace your critical thinking and hands-on development work.
</details>
