/*
 * Copyright (c) 2023 Oracle and/or its affiliates.
 *
 * The Universal Permissive License (UPL), Version 1.0
 *
 * Subject to the condition set forth below, permission is hereby granted to any
 * person obtaining a copy of this software, associated documentation and/or data
 * (collectively the "Software"), free of charge and under any and all copyright
 * rights in the Software, and any and all patent rights owned or freely
 * licensable by each licensor hereunder covering either (i) the unmodified
 * Software as contributed to or provided by such licensor, or (ii) the Larger
 * Works (as defined below), to deal in both
 *
 * (a) the Software, and
 * (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
 * one is included with the Software (each a "Larger Work" to which the Software
 * is contributed by such licensors),
 *
 * without restriction, including without limitation the rights to copy, create
 * derivative works of, display, perform, and distribute the Software and make,
 * use, sell, offer for sale, import, export, have made, and have sold the
 * Software and the Larger Work(s), and to sublicense the foregoing rights on
 * either these or other terms.
 *
 * This license is subject to the following condition:
 * The above copyright notice and either this complete permission notice or at
 * a minimum a reference to the UPL must be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package com.oracle.jdbc.samples.springsharding.controller;

import com.oracle.jdbc.samples.springsharding.dto.RequestNoteDTO;
import com.oracle.jdbc.samples.springsharding.dto.ResponseNoteDTO;
import com.oracle.jdbc.samples.springsharding.dto.UserDTO;
import com.oracle.jdbc.samples.springsharding.mapper.DTOMappers;
import com.oracle.jdbc.samples.springsharding.model.Note;
import com.oracle.jdbc.samples.springsharding.model.User;
import com.oracle.jdbc.samples.springsharding.service.NoteService;
import com.oracle.jdbc.samples.springsharding.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;
import java.util.stream.Collectors;

// We allow CORS to make it easy to test the API
@CrossOrigin(originPatterns = "http://localhost:**")
@org.springframework.stereotype.Controller
@RequestMapping("/users")
public class Controller {
    private final NoteService noteService;
    private final UserService userService;
    private final DTOMappers dtoMappers;

    public Controller(NoteService noteService, UserService userService, DTOMappers dtoMappers) {
        this.noteService = noteService;
        this.userService = userService;
        this.dtoMappers = dtoMappers;
    }

    /**
     * Get all users if authenticated user is admin, authenticated user otherwise.
     */
    @GetMapping
    public ResponseEntity<List<UserDTO>> getUsers() {
        String role = ((User) SecurityContextHolder.getContext().getAuthentication().getPrincipal()).getRole();

        List<UserDTO> response = null;

        if (role.equals("ADMIN")) {
            response = userService.getAllUsers()
                    .stream()
                    .map(dtoMappers::userToUserDTO)
                    .collect(Collectors.toList());
        } else {
            response = List.of(dtoMappers.userToUserDTO(userService.getAuthenticatedUser()));
        }

        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    /**
     * Add a note
     */
    @PostMapping(value = {"/{userId}/notes"})
    public ResponseEntity<ResponseNoteDTO> addNote(@PathVariable Long userId,
                                                   @RequestBody RequestNoteDTO noteBodyDTO) {
        Note note = dtoMappers.requestNoteDTOToNote(noteBodyDTO, null, userId);

        ResponseNoteDTO response = dtoMappers.noteToResponseNoteDTO(noteService.addNote(note));

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * Get all notes for all users
     */
    @GetMapping("/all/notes")
    public ResponseEntity<List<ResponseNoteDTO>> getAllNotes() {
        List<ResponseNoteDTO> response = noteService.getAllNotes()
                .stream()
                .map(dtoMappers::noteToResponseNoteDTO)
                .collect(Collectors.toList());

        return ResponseEntity.ofNullable(response);
    }

    /**
     * Get all notes for a user
     */
    @GetMapping(value = {"/{userId}/notes"})
    public ResponseEntity<List<ResponseNoteDTO>> getNotesForUser(@PathVariable Long userId) {
        List<ResponseNoteDTO> notes = noteService.getNotesForUser(userId)
                .stream()
                .map(dtoMappers::noteToResponseNoteDTO)
                .collect(Collectors.toList());

        return ResponseEntity.ofNullable(notes);
    }

    /**
     * Get a single note identified by userId and noteId
     */
    @GetMapping(value = {"/{userId}/notes/{noteId}"})
    public ResponseEntity<ResponseNoteDTO> getNote(@PathVariable Long userId, @PathVariable Long noteId) {
        ResponseNoteDTO response = dtoMappers.noteToResponseNoteDTO(noteService.getNote(noteId, userId));

        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    /**
     * Update a note
     */
    @PutMapping("/{userId}/notes/{noteId}")
    public ResponseEntity<Void> updateNote(@PathVariable Long userId,
                                                      @PathVariable Long noteId,
                                                      @RequestBody RequestNoteDTO noteBodyDTO) {
        noteService.updateNote(dtoMappers.requestNoteDTOToNote(noteBodyDTO, noteId, userId));

        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    /**
     * Delete a note
     */
    @DeleteMapping("/{userId}/notes/{noteId}")
    public ResponseEntity<Void> deleteNote(@PathVariable Long userId, @PathVariable Long noteId) {
        noteService.removeNote(noteId, userId);

        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }
}
