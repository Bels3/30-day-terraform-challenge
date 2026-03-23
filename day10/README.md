# Day 10 - Terraform Loops and Conditionals

## What I Built
Dynamic infrastructure using count, for_each, for expressions
and conditional logic — the tools that make Terraform feel like
a real programming language.

## Key Demonstrations

### count — simple loop with index-based tracking
Creates N identical resources. Dangerous when list order changes.
Removing an item from the middle renumbers all subsequent resources.

### for_each — safe loop with identity-based tracking  
Keys resources by name not position. Removing one item only
affects that specific resource. Safe for lists that change.

### for expressions — data transformation
Reshapes collections without creating resources.
Used in outputs to expose clean structured data.

### Conditionals — ternary operator
count = var.enable ? 1 : 0 makes resources optional.
locals for environment-based sizing keeps logic centralized.

## Production Best Practice Applied
Backend config passed via -backend-config=backend.hcl
backend.hcl never committed to version control.

## Key Lesson
count uses position. for_each uses identity.
That difference determines whether removing one item
destroys one resource or cascades through your entire list.

## Blog Post
[Insert Medium link here]
