import api from "./api";

export const fetchDashboardData = async () => {
    return await api.get("/dashboard");
}
