/* Copyright (c) 2021, 2022, Oracle and/or its affiliates.
This software is dual-licensed to you under the Universal Permissive License
(UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
either license.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
https://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

DESCRIPTION
Main - Runner class calling multiple methods
*/

package org.oracle;

import oracle.sql.json.OracleJsonArray;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;


public class Main {
	private static DatabaseConfig pds;

	public static void main(String[] args) {

		pds = new DatabaseConfig();
		OracleJsonFactory f = new OracleJsonFactory();

		/*
		 * Example 1
		 * Get all teams
		 */
		System.out.println("Example 1: Retrieve all teams using team_info_dv");
		TeamManager.retrieveTeam(pds);
		System.out.println("\n");

		/*
		 * Example 2
		 * Get specific team
		 */
		System.out.println("Example 2: Retrieve specific teams using team_info_dv");
		TeamManager.retrieveTeam(pds, 2);
		System.out.println("\n");
		/*
		 * Example 3
		 * Create new team using INSERT into team_info_dv
		 */
		System.out.println("Example 3: Create a new team using team_info_dv");
		OracleJsonObject withTeamA = f.createObject();
		withTeamA.put("_id", 3);
		withTeamA.put("name", "Mountain Movers");
		withTeamA.put("region", "South America");
		withTeamA.put("color", "cc2222");

		TeamManager.insertNewTeam(pds, withTeamA);
		System.out.println("\n");
		/*
		 * Example 4
		 * Create new Player in Team using an UPDATE into team_info_dv with JSON_TRANSFORM
		 */
		System.out.println("Example 4: Create a new player using JSON_TRANSFORM and team_info_dv");
		OracleJsonObject withPlayerA = f.createObject();
		withPlayerA.put("playerId", 7);
		withPlayerA.put("name", "PLAYER_GABRIEL");
		withPlayerA.put("position", "Support");

		TeamManager.updateTeam(pds, withPlayerA, 3);
		System.out.println("\n");


		/*
		 * Example 5
		 * Create new Player in Team using INSERT into player_team_info_dv\
		 */
		System.out.println("Example 5: Create a new player using player_team_info_dv");
		OracleJsonObject withPlayerB = f.createObject();
		withPlayerB.put("_id", 8);
		withPlayerB.put("name", "PLAYER_HARVEY");
		withPlayerB.put("position", "Offense");
		withPlayerB.put("teamId", 3);

		TeamManager.insertNewPlayer(pds, withPlayerB, 3);
		System.out.println("\n");

		/*
		 * Example 5
		 * Update Team with new players as a whole JSON document using team_info_dv.
		 *
		 * This example shows that replacing the players with a new
		 * set of players remove the old ones from
		 * the PLAYERS table.
		 *
		 * In this example, an OracleJSONObject is created from
		 * a copy of the oldTeam and an update on the object is done
		 * to replace the players team
		 */
		System.out.println("Example 6: ");
		OracleJsonObject withPlayerC = f.createObject();
		withPlayerC.put("playerId", 10);
		withPlayerC.put("name", "PLAYER_MARK");
		withPlayerC.put("position", "Offense");

		OracleJsonObject withPlayerD = f.createObject();
		withPlayerD.put("playerId", 11);
		withPlayerD.put("name", "PLAYER_NATHAN");
		withPlayerD.put("position", "Offense");

		OracleJsonArray newPlayerArr = f.createArray();
		newPlayerArr.add(withPlayerC);
		newPlayerArr.add(withPlayerD);

		int teamId = 1; // Specify which team
		OracleJsonObject oldTeam = TeamManager.retrieveAndReferenceTeam(pds, teamId);
		if (oldTeam != null) {
			OracleJsonObject newTeam = f.createObject(oldTeam);
			newTeam.put("players", newPlayerArr);
			TeamManager.updateTeamAsAWhole(pds, newTeam, teamId);
			System.out.println("\n");

		}
	}
}