---
description: Test Markdown file content by executing step-by-step instructions
agent: "agent"
argument-hint: "Specify the Markdown file to test"
tools: ["codebase", "terminal"]
---

# Test Markdown File Content

This prompt helps you test the content of Markdown files, particularly those containing step-by-step instructions for various workflows.

## Target File

Test the Markdown file: **${input:markdownFile:path/to/file.md}**

## Instructions

1. **Read and Analyze**: 
   - Carefully read through the entire Markdown file specified above
   - Identify all step-by-step instructions, commands, and procedures
   - Note any prerequisites or setup requirements

2. **Execute Steps**:
   - Follow each instruction in the Markdown file sequentially
   - Execute any commands or code snippets as documented
   - Verify that each step produces the expected results
   - Pay attention to:
     - Command syntax and correctness
     - File paths and references
     - Logical flow and dependencies between steps
     - Missing or incomplete instructions

3. **Issue Handling**:
   - **For simple issues** (typos, minor command errors, outdated syntax):
     - Fix the issue immediately in the Markdown file
     - Document what was fixed in your response
   
   - **For complex issues** (architectural problems, missing major steps, requires significant changes):
     - Do NOT attempt to fix
     - Create a detailed GitHub issue with:
       - Clear title describing the problem
       - Description of what went wrong
       - Which step(s) failed
       - Expected vs actual behavior
       - Any error messages or logs
       - Suggestions for resolution if applicable

4. **Report Results**:
   - Summarize which steps passed and which failed
   - List any fixes made
   - Provide links to any GitHub issues created
   - Note any improvements or clarifications that could enhance the documentation

## Testing Approach

- Test in a clean environment when possible to ensure reproducibility
- Document any assumptions made during testing
- Verify that prerequisites listed in the file are accurate and sufficient
- Check for consistency with other documentation in the repository
- Ensure commands work across different platforms if the guide claims cross-platform support

## Output Format

Provide your test results in the following format:

```
### Test Results for [filename]

**Overall Status**: ✅ PASS / ⚠️ PASS with fixes / ❌ FAIL

**Steps Tested**: [number]
**Steps Passed**: [number]
**Steps Fixed**: [number]
**Issues Created**: [number]

#### Fixes Applied
- [List any quick fixes made to the file]

#### Issues Found
- [List complex issues that require GitHub issues]

#### GitHub Issues Created
- [Link to issue 1]
- [Link to issue 2]

#### Recommendations
- [Any suggestions for improving the documentation]
```

## Notes

- This prompt is designed for testing instructional Markdown files
- Always prioritize accuracy and reproducibility in your testing
- When in doubt about whether to fix or create an issue, prefer creating an issue for visibility
- Consider the impact on users who will follow these instructions
