# Contributing Motivational Quotes 🌟

We love community contributions! If you have a favorite motivational quote that keeps you focused, disciplined, or inspired during your exam preparation, you can add it directly to GATEletics.

Here is how you can contribute your quotes:

## Guidelines for Quotes
- **Theme:** Focus on consistency, learning, persistence, engineering, problem-solving, or general positivity.
- **Length:** Keep them concise (ideally under 100 characters) so they render beautifully on all device screens.
- **Language:** Standard English.
- **Duplicate Check:** Please check the existing `quotes.json` to ensure your quote isn't already there.

---

## Step-by-Step Contribution Guide

### 1. Fork the Repository
Click the **Fork** button at the top-right of the [GATEletics Repository](https://github.com/vishnunandan555/gateletics) to create a copy of the project in your GitHub account.

### 2. Add Your Quote
1. Navigate to the `quotes.json` file in the root of your forked repository.
2. Edit the file directly on GitHub, or clone your fork locally.
3. Add your quote as a new string at the end of the JSON array. Ensure it is comma-separated and respects the JSON syntax.

Example format:
```json
[
  ...
  "Small daily improvements over time lead to stunning results.",
  "Your only limit is you."
]
```

### 3. Open a Pull Request (PR)
1. Commit your changes with a clear commit message, e.g., `feat: add new quote by [Author]`.
2. Push the changes to your fork.
3. Open a **Pull Request** from your fork to the main branch of `gateletics`.
4. We will review and merge it. Once merged, the app will automatically fetch and display your quote to all users!
