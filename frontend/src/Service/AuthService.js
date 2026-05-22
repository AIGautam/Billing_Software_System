import api from "./api";

export const login = async (data) => {
    return await api.post("/login", data);
}
