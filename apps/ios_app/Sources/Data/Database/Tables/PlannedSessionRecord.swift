import Foundation
import GRDB

struct PlannedSessionRecord: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "planned_sessions"

    var id: String
    var programId: String
    var scheduledDate: Double
    var prescriptionData: Data
    var completedSessionId: String?
    var isSkipped: Bool

    init(from session: PlannedSession) throws {
        id = session.id
        programId = session.programId
        scheduledDate = session.scheduledDate.timeIntervalSince1970
        prescriptionData = try JSONEncoder().encode(session.prescription)
        completedSessionId = session.completedSessionId
        isSkipped = session.isSkipped
    }

    init(row: Row) {
        id = row["id"]
        programId = row["programId"]
        scheduledDate = row["scheduledDate"]
        prescriptionData = row["prescriptionData"]
        completedSessionId = row["completedSessionId"]
        isSkipped = row["isSkipped"]
    }

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["programId"] = programId
        container["scheduledDate"] = scheduledDate
        container["prescriptionData"] = prescriptionData
        container["completedSessionId"] = completedSessionId
        container["isSkipped"] = isSkipped
    }

    var asDomain: PlannedSession? {
        guard let prescription = try? JSONDecoder().decode(SessionPrescription.self, from: prescriptionData) else {
            return nil
        }
        return PlannedSession(
            id: id,
            programId: programId,
            scheduledDate: Date(timeIntervalSince1970: scheduledDate),
            prescription: prescription,
            completedSessionId: completedSessionId,
            isSkipped: isSkipped
        )
    }
}
