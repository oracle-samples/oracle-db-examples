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
TeamManager - Class that has requests methods for Team and Player tables and their duality views
*/

package org.oracle;

import oracle.jdbc.OracleType;
import oracle.sql.json.OracleJsonObject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;



public class TeamManager {

		public static void retrieveTeam(DatabaseConfig pds) {
				retrieveAllTeams(pds, -1);
		}
		public static void retrieveTeam(DatabaseConfig pds, int withTeamId) {
				retrieveAllTeams(pds, withTeamId);
		}

		public static void insertNewTeam(DatabaseConfig pds, OracleJsonObject data) {
				try (
						Connection connection = pds.getDatabaseConnection();
						PreparedStatement stmt = connection.prepareStatement(
								"insert into team_info_dv values (?)"
						)
				) {
						stmt.setObject(1, data, OracleType.JSON);

						int created = stmt.executeUpdate();
						if (created > 0) System.out.println("New Team created");

				} catch (SQLException e) {
						e.printStackTrace();
				}
		}


		public static void insertNewPlayer(DatabaseConfig pds, OracleJsonObject data, int teamId) {
				try (
						Connection connection = pds.getDatabaseConnection();
						PreparedStatement stmt = connection.prepareStatement(
								"insert into player_team_info_dv values (?)"
						)
				) {
						stmt.setObject(1, data, OracleType.JSON);

						int created = stmt.executeUpdate();
						if (created > 0) System.out.println("New Player created and added to team.");


				} catch (SQLException e) {
						e.printStackTrace();
				}
		}
		private static void retrieveAllTeams(DatabaseConfig pds, int withTeamId) {
				String query = withTeamId == -1 ? "SELECT data FROM team_info_dv" :
						"SELECT data FROM team_info_dv WHERE json_value(data, '$._id') = ?";

				try (
						Connection connection = pds.getDatabaseConnection();
						PreparedStatement stmt = connection.prepareStatement(query)
				) {
						if (withTeamId > -1) {
								stmt.setInt(1, withTeamId);
						}

						try (ResultSet rs = stmt.executeQuery()) {
								while (rs.next()) {
										OracleJsonObject team = rs.getObject(1, OracleJsonObject.class);
										System.out.println(team.toString());
								}
						}

				} catch (SQLException e) {
						e.printStackTrace();
				}
		}


		public static OracleJsonObject retrieveAndReferenceTeam(DatabaseConfig pds, int withTeamId) {

				try (
						Connection connection = pds.getDatabaseConnection();
						PreparedStatement stmt = connection.prepareStatement("SELECT data FROM team_info_dv WHERE json_value(data, '$._id') = ?")
				) {
						if (withTeamId > -1) {
								stmt.setInt(1, withTeamId);
						}

						try (ResultSet rs = stmt.executeQuery()) {
								if (rs.next()) {
										return rs.getObject(1, OracleJsonObject.class);
								}
						}

				} catch (SQLException e) {
						e.printStackTrace();
				}
				return null;
		}


		public static void updateTeam(DatabaseConfig pds, OracleJsonObject data, int withTeamId) {

				try (
						Connection connection = pds.getDatabaseConnection();
						PreparedStatement stmt = connection.prepareStatement("UPDATE team_info_dv t SET t.data = json_transform(t.data, append '$.players' = json(?)) where JSON_VALUE(t.data, '$._id') = ?")
				) {
						stmt.setObject(1, data, OracleType.JSON);
						stmt.setInt(2, withTeamId);

						int i = stmt.executeUpdate();
						if (i > 0) System.out.println("New Player created and added to team");

				} catch (SQLException e) {
						e.printStackTrace();
				}
		}


		public static void updateTeamAsAWhole(DatabaseConfig pds, OracleJsonObject data, int withTeamId) {

				try (
						Connection connection = pds.getDatabaseConnection();
						PreparedStatement stmt = connection.prepareStatement("UPDATE team_info_dv t SET t.data = ? where JSON_VALUE(t.data, '$._id') = ?")
				) {
						stmt.setObject(1, data, OracleType.JSON);
						stmt.setInt(2, withTeamId);

						int i = stmt.executeUpdate();
						if (i > 0) System.out.println("Updated team with new players");

				} catch (SQLException e) {
						e.printStackTrace();
				}
		}

}
