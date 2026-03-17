# Agent Skill: Create Agent Skill

## Description
Generate a new Agent Skill from a documentation URL or GitHub repository.  
This skill automates the creation of reusable Agent Skills by analyzing source material and structuring it according to the Agent Skills specification.

---

## Input
- **documentation_url** (required): URL to documentation (e.g., https://agentskills.io/specification)  
- **repository_url** (optional): GitHub repository link  
- **context** (optional): Additional notes about the tool or use-case  

---

## Output
- Skill Name  
- Description  
- Inputs  
- Outputs  
- Step-by-step Instructions  
- Example Usage  

---

## Instructions
1. Read and analyze the provided documentation and/or repository  
2. Identify the main purpose and functionality of the tool  
3. Extract key inputs and expected outputs  
4. Generate a structured Agent Skill following a clear format  
5. Ensure clarity, usability, and completeness  
6. Provide an example demonstrating how the skill is used  

---

## Prompt Template

You are an AI agent that creates Agent Skills.

Given:
- Documentation URL: {{documentation_url}}
- Repository URL: {{repository_url}}
- Context: {{context}}

Your task:
1. Analyze the provided resources  
2. Identify the tool’s purpose and capabilities  
3. Generate a complete Agent Skill including:  
   - Skill Name  
   - Description  
   - Inputs  
   - Outputs  
   - Instructions  
   - Example Usage  

Ensure:
- The skill is clear and reusable  
- The format follows Agent Skills best practices  
- The output is structured and easy to understand  

---

## Example

### Input
- documentation_url: https://agentskills.io/specification

### Output

**Skill Name:** Example Agent Skill  
**Description:** Generates structured agent skills from documentation  

**Inputs:**
- documentation_url  
- repository_url  

**Outputs:**
- Structured agent skill definition  

**Instructions:**
1. Read documentation  
2. Extract functionality  
3. Format into skill  

**Example Usage:**
User provides a documentation URL → Agent generates a usable skill definition

## Validation

A good output should:
- Clearly define the skill purpose
- Include structured inputs and outputs
- Provide actionable instructions
- Be reusable by other agents