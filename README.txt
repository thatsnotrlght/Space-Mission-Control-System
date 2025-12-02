## 1. Team & Contact Information

Group Members:
	* Samuel Artiste
	 PID: 6538723
	 FIU email: sarti015@fiu.edu

---

## 2. Compilation & Execution Notes

Programming Environment:
	- Ocelot Server connection: ssh yourname@ocelot-bbhatkal.aul.fiu.edu
	- Compilation Command: The provided Makefile should be used.
	- Build Command: 'make'
	- Execution Command: './space_mission'

---

## 3. Program Features & Implementation Details

This project implements the core memory management and data structure logic for a simulated Space Mission Control System, focusing heavily on defensive programming principles.

Core Functions Implemented:
	- **Dynamic Memory Management:** Creation and cleanup of multi-level structures (Functions 1, 2, 6).
	- **Data Structure Logic:** Dynamic array expansion using realloc() for missions and communications (Functions 2, 3).
	- **File I/O:** Reading structured data (fscanf) and writing formatted reports (fprintf) (Functions 4, 5).
	- **Defensive Programming:** Comprehensive input validation, NULL checking, and multi-level memory deallocation.