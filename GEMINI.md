# AI Prompt & Context Repository

## 📋 Overview
This repository serves as a centralized knowledge base for AI Agent configurations, project contexts, and standard operating procedures (workflows). It is designed to provide consistent, high-quality instructions to AI assistants (Gemini, Claude, etc.) across different development projects and user environments.

## 📂 Directory Structure

### `projects/`
Contains project-specific context files. Each subdirectory represents a distinct project and holds the relevant instruction files for that environment.

*   **Usage**: When working on a specific project, the agent should refer to the `GEMINI.md` (or `CLAUDE.md`) within the corresponding project folder for architecture, tech stack, and development guidelines.
*   **Examples**:
    *   `projects/zdpos_dev/`: Context for the ZDPOS development environment.

### `user/`
Contains global or user-specific configurations for different AI models. These files define the "persona," core principles, and general behavior of the agent, independent of the specific project they are working on.

*   **Subdirectories**:
    *   `.gemini/`: Global instructions for Gemini agents.
    *   `.claude/`: Global instructions for Claude agents.
    *   `.codex/`: Global instructions for OpenAI/Codex agents.

### `workflows/`
Contains reusable workflows and Standard Operating Procedures (SOPs). These documents outline step-by-step guides for common complex tasks.

*   **Example**: `create_openspec_proposal.md` outlines the process for creating and validating OpenSpec proposals.

## 🚀 Usage Guidelines

1.  **Context Loading**: When an agent starts a session or switches context, it should look for the relevant `GEMINI.md` in `projects/<project_name>/` to understand the specific rules and architecture of that project.
2.  **Global Rules**: The files in `user/<model_name>/` serve as the baseline instructions (e.g., "Always use Traditional Chinese," "Follow TDD"). Project-specific rules override global rules if there is a conflict.

## 📝 Conventions

*   **File Naming**:
    *   `GEMINI.md`: Instructions specifically for Gemini.
    *   `CLAUDE.md`: Instructions specifically for Claude.
    *   `AGENTS.md`: General instructions applicable to all agents (often used in OpenSpec).
*   **Language**: Unless specified otherwise in a project context, the default communication language is Traditional Chinese (正體中文).
