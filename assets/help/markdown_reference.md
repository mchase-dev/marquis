# Markdown Reference

A quick reference of all Markdown syntax supported by Marquis.

---

## Headings

```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```

---

## Emphasis

```markdown
**bold text**
*italic text*
***bold and italic***
~~strikethrough~~
```

---

## Links

```markdown
[Link text](https://example.com)
[Link with title](https://example.com "Title")
```

---

## Images

```markdown
![Alt text](image.png)
![Alt text](https://example.com/image.jpg "Optional title")
```

---

## Lists

### Unordered

```markdown
- Item one
- Item two
  - Nested item
  - Another nested item
- Item three
```

### Ordered

```markdown
1. First item
2. Second item
3. Third item
```

### Task Lists

```markdown
- [x] Completed task
- [ ] Incomplete task
- [ ] Another task
```

---

## Block Quotes

```markdown
> This is a block quote.
>
> It can span multiple paragraphs.
```

> This is a block quote.

---

## Code

### Inline Code

```markdown
Use `backticks` for inline code.
```

### Code Blocks

````markdown
```javascript
function hello() {
  console.log("Hello, world!");
}
```
````

Supported languages include: JavaScript, Python, Dart, HTML, CSS, JSON, YAML, Bash, SQL, TypeScript, Rust, Go, Java, C, C++, and many more.

---

## Tables

```markdown
| Header 1 | Header 2 | Header 3 |
| -------- | :------: | -------: |
| Left     | Center   | Right    |
| Cell     | Cell     | Cell     |
```

| Header 1 | Header 2 | Header 3 |
| -------- | :------: | -------: |
| Left     | Center   | Right    |
| Cell     | Cell     | Cell     |

Column alignment: `:---` left, `:---:` center, `---:` right.

---

## Horizontal Rule

```markdown
---
```

or

```markdown
***
```

---

## Inline HTML

Marquis supports these inline HTML elements:

```html
Line<br>break
H<sub>2</sub>O
x<sup>2</sup>
<mark>highlighted</mark>
<kbd>Ctrl</kbd>+<kbd>S</kbd>
```

---

## Escaping

Use a backslash to escape Markdown characters:

```markdown
\*not italic\*
\# not a heading
\[not a link\]
```

---

## GFM Extensions

Marquis supports GitHub Flavored Markdown (GFM):

- Autolinks: URLs like https://example.com are automatically linked
- Task lists with `- [ ]` and `- [x]`
- Tables (as shown above)
- Strikethrough with `~~text~~`
